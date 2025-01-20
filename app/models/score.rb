# == Schema Information
#
# Table name: scores
#
#  id                 :bigint           not null, primary key
#  score              :decimal(5, 2)    not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  feedback_id        :bigint           not null
#  last_updated_by_id :integer          not null
#  score_item_id      :bigint           not null
#
# Indexes
#
#  index_scores_on_feedback_id                    (feedback_id)
#  index_scores_on_last_updated_by_id             (last_updated_by_id)
#  index_scores_on_score_item_id                  (score_item_id)
#  index_scores_on_score_item_id_and_feedback_id  (score_item_id,feedback_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (feedback_id => feedbacks.id)
#  fk_rails_...  (last_updated_by_id => users.id)
#  fk_rails_...  (score_item_id => score_items.id)
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

  default_scope { joins(:score_item).order('score_items.id': :asc) }

  private

  def maybe_complete_feedback
    # If this was the last score to be added, complete the feedback automatically.
    feedback.update(completed: true) if feedback.done_grading?
  end

  def uncomplete
    feedback.update(completed: false) if feedback.completed
  end

  def not_out_of_bounds
    return if score.nil?
    return if score >= BigDecimal('0') && score <= score_item.maximum

    errors.add(:score, 'out of bounds')
  end
end
