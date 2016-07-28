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
  enum status: [:unknown, :correct, :wrong, :timeout]

  belongs_to :exercise
  belongs_to :user

  default_scope { order(created_at: :desc) }
  scope :of_user, ->(user) { where user_id: user.id }
  scope :of_exercise, ->(exercise) { where exercise_id: exercise.id }
end
