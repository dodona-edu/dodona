class Annotation < ApplicationRecord
  include ApplicationHelper

  belongs_to :submission
  belongs_to :user

  validates :user, presence: true
  validates :annotation_text, presence: true, length: { minimum: 1, maximum: 2048 }
  validates :line_nr, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0
  }, if: ->(attr) { attr.line_nr.present? }

  scope :by_submission, ->(submission_id) { where(submission_id: submission_id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  after_create :create_notification

  private

  def create_notification
    Notification.find_by(notifiable: submission)&.destroy
    Notification.create(notifiable: submission, user: submission.user, message: 'annotations.index.new_annotation')
  end
end
