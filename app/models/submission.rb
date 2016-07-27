# == Schema Information
#
# Table name: submissions
#
#  id          :integer          not null, primary key
#  exercise_id :integer
#  user_id     :integer
#  code        :text(65535)
#  result      :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  status      :integer
#

class Submission < ApplicationRecord
  enum status: [:unknown, :correct, :wrong, :timeout]

  belongs_to :exercise
  belongs_to :user

  default_scope { order(created_at: :desc) }
  scope :of_user, ->(user) { where user_id: user.id }
  scope :of_exercise, ->(exercise) { where exercise_id: exercise.id }

  def run
  	runner = PythiaSubmissionRunner.new(self)

  	#TODO; make delayed
  	runner.run
  end
end