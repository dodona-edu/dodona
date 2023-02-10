# == Schema Information
#
# Table name: annotations
#
#  id                  :bigint           not null, primary key
#  line_nr             :integer
#  submission_id       :integer
#  user_id             :integer
#  annotation_text     :text(16777215)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  evaluation_id       :bigint
#  type                :string(255)      default("Annotation"), not null
#  question_state      :integer
#  last_updated_by_id  :integer          not null
#  course_id           :integer          not null
#  saved_annotation_id :bigint
#  thread_root_id      :integer
#
class Annotation < ApplicationRecord
  include ApplicationHelper

  belongs_to :course
  belongs_to :submission
  belongs_to :user
  belongs_to :evaluation, optional: true
  belongs_to :saved_annotation, optional: true, counter_cache: true
  belongs_to :last_updated_by, class_name: 'User'
  belongs_to :thread_root, class_name: 'Annotation', optional: true

  has_many :responses, -> { order(created_at: :asc) }, class_name: 'Annotation', dependent: :destroy, inverse_of: :thread_root, foreign_key: :thread_root_id

  validates :annotation_text, presence: true, length: { minimum: 1, maximum: 10_000 }
  validates :line_nr, allow_nil: true, numericality: {
    greater_than_or_equal_to: 0
  }, if: ->(attr) { attr.line_nr.present? }

  # Only allow responses if the annotation is not a response itself
  validates :thread_root_id, absence: true, if: -> { responses.any? }
  validates_associated :thread_root

  scope :by_submission, ->(submission_id) { where(submission_id: submission_id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :released, -> { left_joins(:evaluation).where(evaluation_id: nil).or(where(evaluations: { released: true })) }
  scope :by_course, ->(course_id) { where(submission: Submission.in_course(Course.find(course_id))) }
  scope :by_username, ->(name) { where(user: User.by_filter(name)) }
  scope :by_exercise_name, ->(name) { where(submission: Submission.by_exercise_name(name)) }

  before_validation :set_last_updated_by, on: :create
  before_validation :set_course_id, on: :create
  after_create :annotate_submission
  after_destroy :destroy_notification
  after_destroy :reset_submission_annotated
  after_save :create_notification

  scope :by_filter, lambda { |filter, skip_user:, skip_exercise:|
    filter.split.map(&:strip).select(&:present?).map do |part|
      scopes = []
      scopes << by_exercise_name(part) unless skip_exercise
      scopes << by_username(part) unless skip_user
      scopes.any? ? merge(scopes.reduce(&:or)) : self
    end.reduce(includes(submission: [:exercise], user: []), &:merge)
  }

  private

  def create_notification
    return if evaluation.present?

    Notification.find_by(notifiable: submission)&.destroy
    Notification.create(notifiable: submission, user: submission.user, message: 'annotations.index.new_annotation')
  end

  def destroy_notification
    Notification.find_by(notifiable: submission)&.destroy unless submission.annotations.released.any?
  end

  def set_last_updated_by
    self.last_updated_by = user
  end

  def set_course_id
    self.course_id = submission.course_id
  end

  def annotate_submission
    submission.update(annotated: true) if evaluation.nil? || evaluation.released?
  end

  def reset_submission_annotated
    submission.update(annotated: false) unless submission.annotations.released.any?
  end
end
