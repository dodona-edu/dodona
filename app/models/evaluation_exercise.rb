# == Schema Information
#
# Table name: evaluation_exercises
#
#  id            :bigint           not null, primary key
#  evaluation_id :bigint
#  exercise_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  visible_score :boolean          default(TRUE), not null
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
    mapped = feedbacks.map(&:score).reject(&:nil?)
    mapped.sum / mapped.count if mapped.any?
  end
end
