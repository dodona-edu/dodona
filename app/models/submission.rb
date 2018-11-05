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
#
class Submission < ApplicationRecord
  SECONDS_BETWEEN_SUBMISSIONS = 5 # Used for rate limiting
  has_one_attached :code
  has_one_attached :result

  enum status: [:unknown, :correct, :wrong, :'time limit exceeded', :running, :queued, :'runtime error', :'compilation error', :'memory limit exceeded', :'internal error']

  belongs_to :exercise
  belongs_to :user
  belongs_to :course, optional: true
  has_one :judge, through: :exercise
  has_one :submission_detail, foreign_key: 'id', dependent: :delete, autosave: true

  validate :code_cannot_contain_emoji, on: :create
  validate :is_not_rate_limited, on: :create, unless: :skip_rate_limit_check?

  after_update :invalidate_stats_cache
  after_create :evaluate_delayed, if: :evaluate?

  default_scope {order(id: :desc)}
  scope :of_user, ->(user) {where user_id: user.id}
  scope :of_exercise, ->(exercise) {where exercise_id: exercise.id}
  scope :before_deadline, ->(deadline) {where('submissions.created_at < ?', deadline)}
  scope :in_course, ->(course) {where course_id: course.id}
  scope :in_series, ->(series) {where(course_id: series.course.id).where(exercise: series.exercises)}

  scope :by_exercise_name, ->(name) {where(exercise: Exercise.by_name(name))}
  scope :by_status, ->(status) {where(status: status.in?(statuses) ? status : -1)}
  scope :by_username, ->(name) {where(user: User.by_filter(name))}
  scope :by_filter, ->(filter, skip_user, skip_exercise, skip_status) do
    filter.split(' ').map(&:strip).select(&:present?).map do |part|
      scopes = []
      scopes << by_exercise_name(part) unless skip_exercise
      scopes << by_status(part) unless skip_status
      scopes << by_username(part) unless skip_user
      scopes.any? ? self.merge(scopes.reduce(&:or)) : self
    end.reduce(&:merge)
  end

  scope :most_recent, -> {
    submissions = select('MAX(submissions.id) as id')
    Submission.joins <<~HEREDOC
      JOIN (#{submissions.to_sql}) most_recent
      ON submissions.id = most_recent.id
    HEREDOC
  }

  scope :most_recent_correct_per_user, -> (*) {
    correct.group(:user_id).most_recent
  }

  scope :exercise_hash, -> {
    s = group(:exercise_id).most_recent
    entries = s.map {|submission| [submission.exercise_id, submission]}
    Hash[entries]
  }

  def initialize(params)
    raise 'please explicitly tell wheter you want to evaluate this submission' unless params.has_key? :evaluate
    @skip_rate_limit_check = params.delete(:skip_rate_limit_check) {false}
    @evaluate = params.delete(:evaluate)
    super
    self.submission_detail = SubmissionDetail.new(id: id, code: params[:code], result: params[:result])
  end

  old_code = instance_method(:code)
  define_method(:code) do
    as_code = old_code.bind(self).()
    if as_code.attached?
      as_code.blob.download
    else
      submission_detail.code
    end
  end

  define_method(:"code=") do |code|
    old_code.bind(self).().attach(ActiveStorage::Blob.create_after_upload!(io: StringIO.new(code), filename: "code", content_type: 'text/plain'))
    submission_detail.code = code if submission_detail
  end

  old_result = instance_method(:result)
  define_method(:result) do
    as_result = old_result.bind(self).()
    if as_result.attached?
      ActiveSupport::Gzip.decompress(as_result.blob.download)
    else
      submission_detail.result
    end
  end

  define_method(:"result=") do |result|
    old_result.bind(self).().attach(ActiveStorage::Blob.create_after_upload!(io: StringIO.new(ActiveSupport::Gzip.compress(result)), filename: "result.json.gz", content_type: 'application/json'))
    submission_detail.result = result if submission_detail
  end

  def copied_to_activestorage?
    old_code.bind(self).().attached? && old_result.bind(self).().attached?
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

  def code_cannot_contain_emoji
    no_emoji_found = code.chars.all? {|c| c.bytes.length < 4}
    errors.add(:code, 'emoji found') unless no_emoji_found
  end

  def is_not_rate_limited
    return if self.user.nil?
    previous = self.user.submissions.most_recent.first
    if previous.present?
      time_since_previous = Time.now - previous.created_at
      errors.add(:submission, 'rate limited') if time_since_previous < SECONDS_BETWEEN_SUBMISSIONS.seconds
    end
  end

  def self.rejudge(submissions, priority = :low)
    submissions.each {|s| s.evaluate_delayed(priority)}
  end

  def self.normalize_status(s)
    return 'correct' if s == 'correct answer'
    return 'wrong' if s == 'wrong answer'
    return s if s.in?(statuses)
    'unknown'
  end

  def invalidate_stats_cache
    memberships = if course
                    course.series_memberships
                  else
                    SeriesMembership.all
                  end
    memberships.where(exercise_id: exercise_id).includes(:exercise, series: :course).find_each(&:invalidate_stats_cache)
  end
end
