# == Schema Information
#
# Table name: submissions
#
#  id          :integer          not null, primary key
#  exercise_id :integer
#  user_id     :integer
#  summary     :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  status      :integer
#  accepted    :boolean          default(FALSE)
#  course_id   :integer
#  fs_key      :string(24)
#

class Submission < ApplicationRecord
  SECONDS_BETWEEN_SUBMISSIONS = 5 # Used for rate limiting
  PUNCHCARD_MATRIX_CACHE_STRING = '/courses/%{course_id}/user/%{user_id}/punchcard_matrix'.freeze
  HEATMAP_MATRIX_CACHE_STRING = '/courses/%{course_id}/user/%{user_id}/heatmap_matrix'.freeze
  BASE_PATH = Rails.application.config.submissions_storage_path
  CODE_FILENAME = 'code'.freeze
  RESULT_FILENAME = 'result.json.gz'.freeze

  enum status: { unknown: 0, correct: 1, wrong: 2, "time limit exceeded": 3, running: 4, queued: 5, "runtime error": 6, "compilation error": 7, "memory limit exceeded": 8, "internal error": 9 }

  belongs_to :exercise
  belongs_to :user
  belongs_to :course, optional: true
  has_one :judge, through: :exercise

  validate :maximum_code_length, on: :create
  validate :not_rate_limited?, on: :create, unless: :skip_rate_limit_check?

  after_create :evaluate_delayed, if: :evaluate?
  after_save :invalidate_caches
  after_destroy :invalidate_caches
  after_destroy :clear_fs
  after_rollback :clear_fs

  default_scope { order(id: :desc) }
  scope :of_user, ->(user) { where user_id: user.id }
  scope :of_exercise, ->(exercise) { where exercise_id: exercise.id }
  scope :before_deadline, ->(deadline) { where('submissions.created_at < ?', deadline) }
  scope :in_course, ->(course) { where course_id: course.id }
  scope :in_series, ->(series) { where(course_id: series.course.id).where(exercise: series.exercises) }
  scope :of_judge, ->(judge) { where(exercise_id: Exercise.where(judge_id: judge.id)) }

  scope :by_exercise_name, ->(name) { where(exercise: Exercise.by_name(name)) }
  scope :by_status, ->(status) { where(status: status.in?(statuses) ? status : -1) }
  scope :by_username, ->(name) { where(user: User.by_filter(name)) }
  scope :by_filter, lambda { |filter, skip_user, skip_exercise|
    filter.split(' ').map(&:strip).select(&:present?).map do |part|
      scopes = []
      scopes << by_exercise_name(part) unless skip_exercise
      scopes << by_username(part) unless skip_user
      scopes.any? ? merge(scopes.reduce(&:or)) : self
    end.reduce(&:merge)
  }
  scope :by_course_labels, ->(labels, course_id) { where(user: CourseMembership.where(course_id: course_id).by_course_labels(labels).map(&:user)) }

  scope :most_recent, lambda {
    submissions = select('MAX(submissions.id) as id')
    Submission.unscoped.joins <<~HEREDOC
      JOIN (#{submissions.to_sql}) most_recent
      ON submissions.id = most_recent.id
    HEREDOC
  }

  scope :most_recent_correct_per_user, lambda { |*|
    correct.group(:user_id).most_recent
  }

  scope :exercise_hash, lambda {
    s = group(:exercise_id).most_recent
    entries = s.map { |submission| [submission.exercise_id, submission] }
    Hash[entries]
  }

  def initialize(params)
    raise 'please explicitly tell whether you want to evaluate this submission' unless params.key? :evaluate

    @skip_rate_limit_check = params.delete(:skip_rate_limit_check) { false }
    @evaluate = params.delete(:evaluate)
    code = params.delete(:code)
    result = params.delete(:result)
    super(params)
    # We need to do this after the rest of the fields are initialized, because we depend on the course_id, user_id, ...
    self.code = code.to_s unless code.nil?
    self.result = result.to_s unless result.nil?
  end

  def code
    File.read(File.join(fs_path, CODE_FILENAME)).force_encoding('UTF-8')
  rescue Errno::ENOENT => e
    ExceptionNotifier.notify_exception e
    ''
  end

  def code=(code)
    FileUtils.mkdir_p fs_path unless File.exist?(fs_path)
    File.write(File.join(fs_path, CODE_FILENAME), code.force_encoding('UTF-8'))
  end

  def result
    ActiveSupport::Gzip.decompress(File.read(File.join(fs_path, RESULT_FILENAME)).force_encoding('UTF-8'))
  rescue Errno::ENOENT, Zlib::GzipFile::Error => e
    ExceptionNotifier.notify_exception e, data: { submission_id: id, status: status, current_user: Current.user&.id }
    nil
  end

  def result=(result)
    FileUtils.mkdir_p fs_path unless File.exist?(fs_path)
    File.open(File.join(fs_path, RESULT_FILENAME), 'wb') { |f| f.write(ActiveSupport::Gzip.compress(result.force_encoding('UTF-8'))) }
  end

  def clean_messages(messages, levels)
    messages.select { |m| !m.is_a?(Hash) || !m.key?(:permission) || levels.include?(m[:permission]) }
  end

  def safe_result(user)
    res = result
    return '' if res.blank?

    json = JSON.parse(res, symbolize_names: true)
    return json.to_json if user.zeus?

    levels = if user.staff? || (course.present? && user.course_admin?(course))
               %w[student staff]
             else
               %w[student]
             end
    json[:groups] = json[:groups].reject { |tab| levels.include? tab[:permission] } if json[:groups].present?
    json[:messages] = clean_messages(json[:messages], levels) if json[:messages].present?
    json[:groups]&.each do |tab|
      tab[:messages] = clean_messages(tab[:messages], levels) if tab[:messages].present?
      tab[:groups]&.each do |context|
        context[:messages] = clean_messages(context[:messages], levels) if context[:messages].present?
        context[:groups]&.each do |testcase|
          testcase[:messages] = clean_messages(testcase[:messages], levels) if testcase[:messages].present?
          testcase[:tests]&.each do |test|
            test[:messages] = clean_messages(test[:messages], levels) if test[:messages].present?
          end
        end
      end
    end
    # Make this in to a string again to keep compatibility with Submission#result
    json.to_json
  end

  def clear_fs
    # If we were destroyed or if we were never saved to the database, delete this submission's directory
    # rubocop:disable Style/GuardClause
    if destroyed? || new_record?
      FileUtils.remove_entry_secure(fs_path) if File.exist?(fs_path)
    end
    # rubocop:enable Style/GuardClause
  end

  def on_filesystem?
    File.exist?(File.join(fs_path, RESULT_FILENAME)) && File.exist?(File.join(fs_path, CODE_FILENAME))
  end

  def evaluate?
    @evaluate
  end

  def skip_rate_limit_check?
    @skip_rate_limit_check
  end

  def evaluate_delayed(priority = :normal)
    queue = if priority == :high
              'high_priority_submissions'
            elsif priority == :low
              'low_priority_submissions'
            else
              'submissions'
            end

    update(
      status: 'queued',
      result: '',
      summary: nil
    )

    delay(queue: queue).evaluate
  end

  def evaluate
    runner = judge.runner.new(self)
    save_result runner.run
  end

  def save_result(result_hash)
    self.result = result_hash.to_json
    self.status = Submission.normalize_status result_hash[:status]
    self.accepted = result_hash[:accepted]
    self.summary = result_hash[:description]
    save
  end

  def maximum_code_length
    # code is saved in a TEXT field which has max size 2^16 - 1 bytes
    errors.add(:code, 'too long') if code.bytesize >= 64.kilobytes
  end

  def not_rate_limited?
    return if user.nil?

    previous = user.submissions.most_recent.first
    return if previous.blank?

    time_since_previous = Time.zone.now - previous.created_at
    errors.add(:submission, 'rate limited') if time_since_previous < SECONDS_BETWEEN_SUBMISSIONS.seconds
  end

  def fs_path
    File.join(BASE_PATH, (course_id.present? ? course_id.to_s : 'no_course'), user_id.to_s, exercise_id.to_s, fs_key)
  end

  def fs_key
    return self[:fs_key] if self[:fs_key].present?

    begin
      key = Random.new.alphanumeric(24)
    end while Submission.find_by(fs_key: key).present?
    self.fs_key = key
    # We don't want to trigger callbacks (and invalidate the cache as a result)
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:fs_key, self[:fs_key]) unless new_record?
    # rubocop:enable Rails/SkipsModelValidations
    key
  end

  def self.rejudge(submissions, priority = :low)
    submissions.each { |s| s.evaluate_delayed(priority) }
  end

  def self.normalize_status(status)
    return 'correct' if status == 'correct answer'
    return 'wrong' if status == 'wrong answer'
    return status if status.in?(statuses)

    'unknown'
  end

  def invalidate_caches
    exercise.invalidate_users_correct
    exercise.invalidate_users_tried
    user.invalidate_attempted_exercises
    user.invalidate_correct_exercises

    return if course.blank?

    course.invalidate_correct_solutions
    exercise.invalidate_users_correct(course: course)
    exercise.invalidate_users_tried(course: course)
    user.invalidate_attempted_exercises(course: course)
    user.invalidate_correct_exercises(course: course)
  end

  def self.get_punchcard_matrix(user, course)
    Rails.cache.fetch(format(PUNCHCARD_MATRIX_CACHE_STRING, course_id: course.present? ? course.id : 'global', user_id: user.present? ? user.id : 'global')) do
      submissions = Submission.all
      submissions = submissions.of_user(user) if user.present?
      submissions = submissions.in_course(course) if course.present?
      submissions = submissions.pluck(:id, :created_at)
      {
        latest: submissions.first.present? ? submissions.first[0] : 0,
        matrix: submissions.map { |_, d| "#{d.utc.wday > 0 ? d.utc.wday - 1 : 6}, #{d.utc.hour}" }
                           .group_by(&:itself).transform_values(&:count)
      }
    end
  end

  def self.update_punchcard_matrix(user, course)
    old = get_punchcard_matrix(user, course)
    submissions = Submission.all
    submissions = submissions.of_user(user) if user.present?
    submissions = submissions.in_course(course) if course.present?
    submissions = submissions.where('id > ?', old.present? ? old[:latest] : 0)
    submissions = submissions.pluck(:id, :created_at)

    return unless submissions.any?

    to_merge = submissions.map { |_, d| "#{d.utc.wday > 0 ? d.utc.wday - 1 : 6}, #{d.utc.hour}" }
                          .group_by(&:itself).transform_values(&:count)
    result = {
      latest: submissions.first[0],
      matrix: old[:matrix].merge(to_merge) { |_k, v1, v2| v1 + v2 }
    }
    Rails.cache.write(format(PUNCHCARD_MATRIX_CACHE_STRING, course_id: course.present? ? course.id : 'global', user_id: user.present? ? user.id : 'global'), result)
  end

  def self.get_heatmap_matrix(user, course)
    Rails.cache.fetch(format(HEATMAP_MATRIX_CACHE_STRING, course_id: course.present? ? course.id : 'global', user_id: user.present? ? user.id : 'global')) do
      submissions = Submission.all
      submissions = submissions.of_user(user) if user.present?
      submissions = submissions.in_course(course) if course.present?
      submissions = submissions.pluck(:id, :created_at)
      {
        latest: submissions.first.present? ? submissions.first[0] : 0,
        matrix: submissions.map { |_, d| d.strftime('%Y-%m-%d') }.group_by(&:itself).transform_values(&:count)
      }
    end
  end

  def self.update_heatmap_matrix(user, course)
    old = get_heatmap_matrix(user, course)
    submissions = Submission.all
    submissions = submissions.of_user(user) if user.present?
    submissions = submissions.in_course(course) if course.present?
    submissions = submissions.where('id > ?', old.present? ? old[:latest] : 0)
    submissions = submissions.pluck(:id, :created_at)

    return unless submissions.any?

    to_merge = submissions.map { |_, d| d.strftime('%Y-%m-%d') }.group_by(&:itself).transform_values(&:count)
    result = {
      latest: submissions.first[0],
      matrix: old[:matrix].merge(to_merge) { |_k, v1, v2| v1 + v2 }
    }
    Rails.cache.write(format(HEATMAP_MATRIX_CACHE_STRING, course_id: course.present? ? course.id : 'global', user_id: user.present? ? user.id : 'global'), result)
  end
end
