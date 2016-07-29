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
  enum status: [:unknown, :correct, :wrong, :timeout, :running, :queued, :'runtime error', :'compilation error']

  belongs_to :exercise
  belongs_to :user

  # docs say after_commit_create
  after_create :evaluate

  default_scope { order(created_at: :desc) }
  scope :of_user, ->(user) { where user_id: user.id }
  scope :of_exercise, ->(exercise) { where exercise_id: exercise.id }

  # TODO; can delayed_jobs_active_records really only process active record methods?
  # TODO; does delayed_jobs have some sort of method name caching? 
  #       renaming these functions to enqueue/evaluate results in stack overflows? how even
  def evaluate
    self.status = 'queued'
    self.save

    self.delay.pls
  end

  def pls
    runner = PythiaSubmissionRunner.new(self)

    runner.run
  end

  def result=(result)
    self[:result] = ActiveSupport::Gzip.compress(result)
  end

  def result
    ActiveSupport::Gzip.decompress(self[:result])
  end

  def self.normalize_status(s)
    if s == 'correct answer'
      return 'correct'
    elsif s == 'wrong answer'
      return 'wrong'
    elsif s.in?(statuses)
      return s
    else
      return 'unknown'
    end
  end
  
end
