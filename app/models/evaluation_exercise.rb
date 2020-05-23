# == Schema Information
#
# Table name: evaluation_exercises
#
#  id            :bigint           not null, primary key
#  evaluation_id :bigint
#  exercise_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class EvaluationExercise < ApplicationRecord
  belongs_to :exercise
  belongs_to :evaluation
  has_many :feedbacks, dependent: :destroy

  def metadata
    {
      done: feedbacks.complete.count,
      total: feedbacks.count
    }
  end
end
