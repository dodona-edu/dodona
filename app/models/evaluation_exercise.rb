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
  has_many :rubrics, dependent: :destroy

  validates :exercise_id, uniqueness: { scope: :evaluation_id }

  def metadata
    {
      done: feedbacks.complete.count,
      total: feedbacks.count
    }
  end

  def maximum_score
    rubrics.map(&:maximum).sum
  end
end
