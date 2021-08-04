# == Schema Information
#
# Table name: scores
#
#  id                 :bigint           not null, primary key
#  score_item_id      :bigint           not null
#  feedback_id        :bigint           not null
#  score              :decimal(5, 2)    not null
#  last_updated_by_id :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
class Score < ApplicationRecord
  attribute :score, :decimal
  # Used to detect conflicts
  attribute :expected_score, :decimal

  belongs_to :score_item
  belongs_to :feedback
  belongs_to :last_updated_by, class_name: 'User'

  after_destroy :uncomplete, unless: :destroyed_by_association
  after_save :maybe_complete_feedback

  validates :score, presence: true, numericality: { greater_than: -1000, less_than: 1000 }
  validates :score_item_id, uniqueness: { scope: :feedback_id }
  validate :not_out_of_bounds

  private

  def maybe_complete_feedback
    # If this was the last score to be added, complete the feedback automatically.
    feedback.update(completed: true) if feedback.done_grading?
  end

  def uncomplete
    feedback.update(completed: false)
  end

  def not_out_of_bounds
    return if score.nil?
    return if score >= BigDecimal('0') && score <= score_item.maximum

    errors.add(:score, 'out of bounds')
  end
end
