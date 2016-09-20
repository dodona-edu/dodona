# == Schema Information
#
# Table name: submissions
#
#  id          :integer          not null, primary key
#  exercise_id :integer
#  user_id     :integer
#  code        :text(65535)
#  summary     :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  status      :integer
#  result      :binary(16777215)
#  accepted    :boolean          default(FALSE)
#

class Submission < ApplicationRecord
  enum status: [:unknown, :correct, :wrong, :'time limit exceeded', :running, :queued, :'runtime error', :'compilation error', :'memory limit exceeded', :'internal error']

  belongs_to :exercise
  belongs_to :user
  has_one :judge, through: :exercise

  validates :exercise, presence: true
  validates :user, presence: true

  # docs say to use after_commit_create, doesn't even work
  after_create :evaluate_delayed

  default_scope { order(created_at: :desc) }
  scope :of_user, ->(user) { where user_id: user.id }
  scope :of_exercise, ->(exercise) { where exercise_id: exercise.id }
  scope :before_deadline, ->(deadline) { where('created_at < ?', deadline) }
  scope :in_course, ->(course) { joins('LEFT JOIN course_memberships ON submissions.user_id = course_memberships.user_id').where('course_memberships.course_id = ?', course.id) }

  scope :by_exercise_name, -> (name) { joins(:exercise, :user).where('exercises.name_nl LIKE ? OR exercises.name_en LIKE ? OR exercises.path LIKE ?', "%#{name}%", "%#{name}%", "%#{name}%") }
  scope :by_status, -> (status) { joins(:exercise, :user).where(status: status.in?(statuses) ? status : -1) }
  scope :by_username, -> (username) { joins(:exercise, :user).where('users.username LIKE ?', "%#{username}%") }
  scope :by_filter, -> (query) { by_exercise_name(query).or(by_status(query)).or(by_username(query)) }

  # TODO; can delayed_jobs_active_records really only process active record methods?
  def evaluate_delayed
    update(
      status: 'queued',
      result: '',
      summary: nil
    )

    delay.evaluate
  end

  def file_name
    "#{exercise.name.tr(' ', '_')}_#{user.username}.#{file_extension}"
  end

  def file_extension
    return 'py' if exercise.programming_language == 'python'
    return 'js' if exercise.programming_language == 'JavaScript'
    'txt'
  end

  def evaluate
    runner = judge.runner.new(self)

    runner.run
  end

  def result=(result)
    self[:result] = ActiveSupport::Gzip.compress(result)
  end

  def result
    ActiveSupport::Gzip.decompress(self[:result])
  end

  def self.normalize_status(s)
    return 'correct' if s == 'correct answer'
    return 'wrong' if s == 'wrong answer'
    return s if s.in?(statuses)
    'unknown'
  end
end
