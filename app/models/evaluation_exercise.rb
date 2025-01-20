# == Schema Information
#
# Table name: evaluation_exercises
#
#  id            :bigint           not null, primary key
#  visible_score :boolean          default(TRUE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  evaluation_id :bigint
#  exercise_id   :integer
#
# Indexes
#
#  index_evaluation_exercises_on_evaluation_id                  (evaluation_id)
#  index_evaluation_exercises_on_exercise_id                    (exercise_id)
#  index_evaluation_exercises_on_exercise_id_and_evaluation_id  (exercise_id,evaluation_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (evaluation_id => evaluations.id)
#  fk_rails_...  (exercise_id => activities.id)
#
class EvaluationExercise < ApplicationRecord
  belongs_to :exercise
  belongs_to :evaluation
  has_many :feedbacks, dependent: :destroy
  has_many :score_items, dependent: :destroy

  validates :exercise_id, uniqueness: { scope: :evaluation_id }

  def metadata
    {
      done: feedbacks.complete.count,
      total: feedbacks.count
    }
  end

  def maximum_score
    mapped = score_items.map(&:maximum)
    mapped.sum if mapped.any?
  end

  def average_score
    mapped = feedbacks.map(&:score).compact
    mapped.sum / mapped.count if mapped.any?
  end
end
