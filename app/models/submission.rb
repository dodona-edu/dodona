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
  enum status: [:unknown, :correct, :wrong, :'time limit exceeded', :running, :queued, :'runtime error', :'compilation error', :'memory limit exceeded', :'internal error']

  belongs_to :exercise
  belongs_to :user
  belongs_to :course, optional: true
  has_one :judge, through: :exercise
  has_one :submission_detail, foreign_key: 'id', dependent: :delete, autosave: true

  delegate :code, :"code=", :result, :"result=", to: :submission_detail, allow_nil: true

  validate :code_cannot_contain_emoji, on: :create

  # docs say to use after_commit_create, doesn't even work
  after_create :evaluate_delayed
  after_update :invalidate_stats_cache

  default_scope { order(id: :desc) }
  scope :of_user, ->(user) { where user_id: user.id }
  scope :of_exercise, ->(exercise) { where exercise_id: exercise.id }
  scope :before_deadline, ->(deadline) { where('created_at < ?', deadline) }
  scope :in_course, ->(course) { where course_id: course.id }
  scope :in_series, ->(series) { joins(exercise: :series_memberships).where(series_memberships: { series_id: series.id }) }

  scope :by_exercise_name, ->(name) { joins(:exercise, :user).where('exercises.name_nl LIKE ? OR exercises.name_en LIKE ? OR exercises.path LIKE ?', "%#{name}%", "%#{name}%", "%#{name}%") }
  scope :by_status, ->(status) { joins(:exercise, :user).where(status: status.in?(statuses) ? status : -1) }
  scope :by_username, ->(username) { joins(:exercise, :user).where('users.username LIKE ?', "%#{username}%") }
  scope :by_filter, ->(query) { by_exercise_name(query).or(by_status(query)).or(by_username(query)) }

  def initialize(params)
    super
    self.submission_detail = SubmissionDetail.new(id: id, code: params[:code], result: params[:result])
  end

  def evaluate_delayed(priority = :normal)
    p_value = if priority == :high
                -10
              elsif priority == :low
                10
              else
                0
              end

    update(
      status: 'queued',
      result: '',
      summary: nil
    )

    delay(priority: p_value).evaluate
  end

  def evaluate
    runner = judge.runner.new(self)

    runner.run
  end

  def code_cannot_contain_emoji
    no_emoji_found = code.chars.all? { |c| c.bytes.length < 4 }
    errors.add(:code, 'emoji found') unless no_emoji_found
  end

  def self.rejudge(submissions, priority = :low)
    submissions.each { |s| s.evaluate_delayed(priority) }
  end

  def self.normalize_status(s)
    return 'correct' if s == 'correct answer'
    return 'wrong' if s == 'wrong answer'
    return s if s.in?(statuses)
    'unknown'
  end

  def invalidate_stats_cache
    # could be more fine grained by also filtering on series_id but makes the invalidation a lot slower
    SeriesMembership.where(exercise_id: exercise_id).find_each(&:invalidate_stats_cache)
  end
end
