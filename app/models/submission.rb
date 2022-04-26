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
#  number      :integer
#

class Submission < ApplicationRecord
  include Cacheable
  include ActiveModel::Dirty

  SECONDS_BETWEEN_SUBMISSIONS = 5 # Used for rate limiting
  PUNCHCARD_MATRIX_CACHE_STRING = '/courses/%<course_id>s/user/%<user_id>s/timezone/%<timezone>s/punchcard_matrix'.freeze
  HEATMAP_MATRIX_CACHE_STRING = '/courses/%<course_id>s/user/%<user_id>s/heatmap_matrix'.freeze
  BASE_PATH = Rails.application.config.submissions_storage_path
  CODE_FILENAME = 'code'.freeze
  RESULT_FILENAME = 'result.json.gz'.freeze

  enum status: { unknown: 0, correct: 1, wrong: 2, 'time limit exceeded': 3, running: 4, queued: 5, 'runtime error': 6, 'compilation error': 7, 'memory limit exceeded': 8, 'internal error': 9, 'output limit exceeded': 10 }

  belongs_to :exercise, optional: false
  belongs_to :user, optional: false
  belongs_to :course, optional: true
  has_one :judge, through: :exercise
  has_one :notification, as: :notifiable, dependent: :destroy
  has_many :annotations, dependent: :destroy
  has_many :questions, dependent: :destroy
  has_many :feedbacks, dependent: :restrict_with_error

  validate :maximum_code_length, on: :create
  validate :not_rate_limited?, on: :create, unless: :skip_rate_limit_check?

  before_save :report_if_internal_error
  before_create :set_number
  after_create :evaluate_delayed, if: :evaluate?
  before_update :update_fs
  after_destroy :invalidate_caches
  after_destroy :clear_fs
  after_save :update_exercise_status
  after_save :invalidate_caches
  after_rollback :clear_fs

  default_scope { order(id: :desc) }
  scope :of_user, ->(user) { where user_id: user.id }
  scope :of_exercise, ->(exercise) { where exercise_id: exercise.id }
  scope :before_deadline, ->(deadline) { where('submissions.created_at < ?', deadline) }
  scope :in_time_range, ->(start_date, end_date) { where(created_at: start_date.to_datetime..end_date.to_datetime) }
  scope :in_course, ->(course) { where course_id: course.id }
  scope :in_series, ->(series) { where(course_id: series.course.id).where(exercise: series.exercises) }
  scope :of_judge, ->(judge) { where(exercise_id: Exercise.where(judge_id: judge.id)) }
  scope :from_students, ->(course) { where(user: course.enrolled_members) }

  scope :judged, -> { where.not(status: %i[running queued]) }
  scope :by_exercise_name, ->(name) { where(exercise: Exercise.by_name(name)) }
  scope :by_status, ->(status) { where(status: status.in?(statuses) ? status : -1) }
  scope :by_username, ->(name) { where(user: User.by_filter(name)) }
  scope :by_filter, lambda { |filter, skip_user:, skip_exercise:|
    filter.split.map(&:strip).select(&:present?).map do |part|
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

  scope :least_recent, lambda {
    submissions = select('MIN(submissions.id) as id')
    Submission.unscoped.joins <<~HEREDOC
      JOIN (#{submissions.to_sql}) least_recent
      ON submissions.id = least_recent.id
    HEREDOC
  }

  scope :first_correct_per_ex_per_user, lambda { |*|
    correct.group(:exercise_id, :user_id).least_recent
  }

  scope :order_by_user, ->(direction) { includes(:user).reorder 'users.first_name': direction, 'users.last_name': direction, id: :desc }
  scope :order_by_exercise, lambda { |direction| includes(:exercise).reorder "activities.name_#{I18n.locale}": direction, id: :desc }
  scope :order_by_created_at, ->(direction) { reorder created_at: direction, id: :desc }
  scope :order_by_status, ->(direction) { reorder status: direction, id: :desc }

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
    return nil if queued? || running?

    ActiveSupport::Gzip.decompress(File.read(File.join(fs_path, RESULT_FILENAME)).force_encoding('UTF-8'))
  rescue Errno::ENOENT, Zlib::GzipFile::Error => e
    ExceptionNotifier.notify_exception e, data: { submission_id: id, status: status, current_user: Current.user&.id }
    nil
  end

  def result=(result)
    FileUtils.mkdir_p fs_path unless File.exist?(fs_path)
    File.binwrite(File.join(fs_path, RESULT_FILENAME), ActiveSupport::Gzip.compress(result.force_encoding('UTF-8')))
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
    json[:groups] = json[:groups].select { |tab| levels.include?(tab[:permission] || 'student') } if json[:groups].present?
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
    # rubocop:disable Style/GuardClause, Style/SoleNestedConditional
    if destroyed? || new_record?
      FileUtils.remove_entry_secure(fs_path) if File.exist?(fs_path)
    end
    # rubocop:enable Style/GuardClause, Style/SoleNestedConditional
  end

  def on_filesystem?
    File.exist?(File.join(fs_path, RESULT_FILENAME)) && File.exist?(File.join(fs_path, CODE_FILENAME))
  end

  def evaluate?
    @evaluate
  end

  def annotated?
    annotations.left_joins(:evaluation).released.any?
  end

  def skip_rate_limit_check?
    @skip_rate_limit_check
  end

  def evaluate_delayed(priority = :normal)
    return if status.in?(%w[queued running])

    queue = case priority
            when :high
              'high_priority_submissions'
            when :low
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
    save_result SubmissionRunner.new(self).run
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

  def self.rejudge_delayed(submissions, priority = :low)
    delay.rejudge(submissions, priority)
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

  def update_exercise_status
    return if status.in?(%i[queued running])

    exercise.activity_statuses_for(user, course).each(&:update_values)
  end

  def invalidate_caches
    exercise.invalidate_delayed_users_correct
    exercise.invalidate_delayed_users_tried
    user.invalidate_attempted_exercises
    user.invalidate_correct_exercises

    return if course.blank?

    # Invalidate the completion status of this exercise, for every series in
    # the current course that contains this exercise, for the current user.
    # Afterwards, invalidate the completion status of the series itself as well.
    exercise.series.where(course_id: course_id).find_each do |ex_series|
      ex_series.invalidate_caches(user)
    end

    # Invalidate other statistics.
    course.invalidate_delayed_correct_solutions
    exercise.invalidate_delayed_users_correct(course: course)
    exercise.invalidate_delayed_users_tried(course: course)
    user.invalidate_attempted_exercises(course: course)
    user.invalidate_correct_exercises(course: course)
  end

  def self.submissions_since(latest, options)
    submissions = Submission.all
    submissions = submissions.of_user(options[:user]) if options[:user].present?
    submissions = submissions.in_course(options[:course]) if options[:course].present?
    submissions = submissions.where(id: (latest + 1)..) if latest > 0
    submissions
  end

  def self.punchcard_matrix(options, base = { until: 0, value: {} })
    submissions = submissions_since(base[:until], options)
    return base unless submissions.any?

    value = base[:value]

    submissions.find_in_batches do |subs|
      value = value.merge(subs.map(&:created_at)
                              .map { |d| d.in_time_zone(options[:timezone]) }
                              .map { |d| "#{d.wday > 0 ? d.wday - 1 : 6}, #{d.hour}" }
                              .group_by(&:itself)
                              .transform_values(&:count)) { |_key, count1, count2| count1 + count2 }
    end

    {
      until: submissions.first&.id || 0,
      value: value
    }
  end

  updateable_class_cacheable(
    :punchcard_matrix,
    lambda do |options|
      format(PUNCHCARD_MATRIX_CACHE_STRING,
             course_id: options[:course].present? ? options[:course].id.to_s : 'global',
             user_id: options[:user].present? ? options[:user].id.to_s : 'global',
             timezone: options[:timezone].utc_offset)
    end
  )

  def self.heatmap_matrix(options = {}, base = { until: 0, value: {} })
    submissions = submissions_since(base[:until], options)
    return base unless submissions.any?

    value = base[:value]

    submissions.find_in_batches do |subs|
      value = value.merge(subs.map(&:created_at)
                              .map { |d| d.strftime('%Y-%m-%d') }
                              .group_by(&:itself)
                              .transform_values(&:count)) { |_key, count1, count2| count1 + count2 }
    end

    {
      until: submissions.first&.id || 0,
      value: value
    }
  end

  updateable_class_cacheable(
    :heatmap_matrix,
    lambda do |options|
      format(HEATMAP_MATRIX_CACHE_STRING,
             course_id: options[:course].present? ? options[:course].id.to_s : 'global',
             user_id: options[:user].present? ? options[:user].id.to_s : 'global')
    end
  )

  def self.violin_matrix(options = {})
    submissions = submissions_since(0, options)
    submissions = submissions.in_series(options[:series]) if options[:series].present?
    submissions = submissions.judged
    submissions = submissions.from_students(options[:series].course)

    value = {}
    # part 1: group by exercise and user
    submissions.find_in_batches do |subs|
      value = value.merge(
        subs.map { |s| [s.exercise_id, s.user_id] }
        .group_by(&:itself) # group by exercise and user
        .transform_values(&:count) # calc amount of submissions per user per exercise
      ) { |_key, count1, count2| count1 + count2 }
    end

    # part 2: group by exercise and aggregate amount per user in an array
    # this can only be done on the complete result since this part drops the user_id
    value = value
            .group_by { |ex_u_ids, _| ex_u_ids[0] } # group by exercise (key: ex_id, value: [[ex_id, u_id], count])
            .transform_values { |v| v.map { |ex_u_ids_count| ex_u_ids_count[1] } } # only retain count (as value)
    {
      value: value
    }
  end

  def self.stacked_status_matrix(options = {})
    submissions = submissions_since(0, options)
    submissions = submissions.in_series(options[:series]) if options[:series].present?
    submissions = submissions.judged
    submissions = submissions.from_students(options[:series].course)

    value = {}
    submissions.find_in_batches do |subs|
      data = subs.map { |s| [s.exercise_id, s.status] }
                 .group_by(&:itself)
                 .transform_values(&:count)
                 .group_by { |ex_id_status, _| ex_id_status[0] } # group by exercise
      transformed = data.transform_values do |v|
        v.to_h do |ex_id_status_count| # -> ex_id -> { status -> count }
          status = ex_id_status_count[0][1]
          count = ex_id_status_count[1]
          [status, count]
        end
      end
      value = value.merge(transformed) { |_k, h1, h2| h1.merge(h2) { |_k, count1, count2| count1 + count2 } }
    end
    {
      value: value
    }
  end

  def self.timeseries_matrix(options = {})
    submissions = submissions_since(0, options)
    submissions = submissions.in_series(options[:series]) if options[:series].present?
    submissions = submissions.judged
    submissions = submissions.from_students(options[:series].course)

    first_sub = submissions.any? ? submissions.least_recent.first.created_at : nil
    last_sub = submissions.any? ? submissions.most_recent.first.created_at : nil

    submissions = submissions.in_time_range(options[:start], options[:end]) if options[:end].present?

    value = {}

    submissions.find_in_batches do |subs|
      value = value.merge(
        subs.map { |s| [s.exercise_id, s.created_at, s.status] }
          .group_by(&:itself) # group duplicates
          .transform_values(&:count) # count amount of duplicates
      ) { |_k, v1, v2| v1 + v2 }
    end

    # further transformations not in batches since merge would get complicated
    value = value.group_by { |k, _| k[0] } # group by exercise id
    # drop exId in values, create record of date, status and count
    value = value.transform_values do |values|
      values.map do |v|
        { date: v[0][1], status: v[0][2], count: v[1] }
      end
    end

    {
      value: value,
      first_sub: first_sub,
      last_sub: last_sub
    }
  end

  def self.cumulative_timeseries_matrix(options = {})
    submissions = submissions_since(0, options)
    submissions = submissions.in_series(options[:series]) if options[:series].present?
    submissions = submissions.judged
    submissions = submissions.first_correct_per_ex_per_user
    submissions = submissions.from_students(options[:series].course)

    # fetching regular data to be shown on the graph
    value = {}
    submissions.find_in_batches do |subs|
      value = value.merge(
        subs.map { |s| [s.exercise_id, s.created_at] }
          .group_by { |ex_id_date| ex_id_date[0] } # group by exId
          # drop exId from values
          .transform_values { |values| values.map { |v| v[1] } }
      ) { |_k, v1, v2| v1 + v2 }
    end
    {
      value: value
    }
  end

  private

  def old_fs_path
    c_id = course_id_changed? ? course_id_was : course_id
    e_id = exercise_id_changed? ? exercise_id_was : exercise_id
    u_id = user_id_changed? ? user_id_was : user_id

    File.join(BASE_PATH, (c_id.present? ? c_id.to_s : 'no_course'), u_id.to_s, e_id.to_s, fs_key)
  end

  def update_fs
    old_path = old_fs_path
    new_path = fs_path
    return if old_path == new_path

    # Only apply the changes on the filesystem, after the complete transaction has executed successfully
    AfterCommitEverywhere.after_commit do
      FileUtils.mkdir_p File.dirname new_path
      FileUtils.move old_path, new_path
    end
  end

  def report_if_internal_error
    return unless status_changed? && send(:'internal error?')

    ExceptionNotifier.notify_exception(
      Exception.new("Submission(#{id}) status was changed to internal error"),
      data: {
        host: `hostname`,
        judge: judge.name,
        submission: inspect,
        url: Rails.application.routes.url_helpers.submission_url('en', self, host: Rails.application.config.default_host)
      }
    )
  end

  def set_number
    submissions = Submission.of_user(user).of_exercise(exercise)
    submissions = submissions.where(course_id: course&.id)
    self.number = submissions.count + 1
  end
end
