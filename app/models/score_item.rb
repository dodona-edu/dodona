# == Schema Information
#
# Table name: score_items
#
#  id                     :bigint           not null, primary key
#  evaluation_exercise_id :bigint           not null
#  maximum                :decimal(5, 2)    not null
#  name                   :string(255)      not null
#  visible                :boolean          default(TRUE), not null
#  description            :text(65535)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class ScoreItem < ApplicationRecord
  belongs_to :evaluation_exercise

  has_many :scores, dependent: :destroy
  # Who updated the score item. This is used to modify scores if necessary.
  attr_accessor :last_updated_by

  after_create :uncomplete_feedbacks_and_set_blank_to_zero
  after_update :uncomplete_feedbacks_if_maximum_changed

  validates :maximum, numericality: { greater_than: 0, less_than: 1000 }

  private

  def uncomplete_feedbacks_if_maximum_changed
    # If we didn't modify the maximum, it has no impact on the existing feedbacks.
    return unless saved_change_to_maximum?

    uncomplete_feedbacks
  end

  def uncomplete_feedbacks_and_set_blank_to_zero
    evaluation_exercise
      .feedbacks
      .find_each do |feedback|
      Score.create(score_item: self, feedback: feedback, score: 0, last_updated_by: last_updated_by) if feedback.submission.blank?
    end

    uncomplete_feedbacks
  end

  def uncomplete_feedbacks
    evaluation_exercise
      .feedbacks
      .complete
      .find_each do |feedback|
      feedback.update(completed: false) if feedback.submission.present?
    end
  end
end
