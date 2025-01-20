# == Schema Information
#
# Table name: annotations
#
#  id                  :bigint           not null, primary key
#  annotation_text     :text(16777215)
#  column              :integer
#  columns             :integer
#  line_nr             :integer
#  question_state      :integer
#  rows                :integer          default(1), not null
#  type                :string(255)      default("Annotation"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  course_id           :integer          not null
#  evaluation_id       :bigint
#  last_updated_by_id  :integer          not null
#  saved_annotation_id :bigint
#  submission_id       :integer
#  thread_root_id      :integer
#  user_id             :integer
#
# Indexes
#
#  index_annotations_on_course_id_and_type_and_question_state  (course_id,type,question_state)
#  index_annotations_on_evaluation_id                          (evaluation_id)
#  index_annotations_on_last_updated_by_id                     (last_updated_by_id)
#  index_annotations_on_saved_annotation_id                    (saved_annotation_id)
#  index_annotations_on_submission_id                          (submission_id)
#  index_annotations_on_user_id                                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_id => courses.id)
#  fk_rails_...  (evaluation_id => evaluations.id)
#  fk_rails_...  (last_updated_by_id => users.id)
#  fk_rails_...  (saved_annotation_id => saved_annotations.id)
#  fk_rails_...  (submission_id => submissions.id)
#  fk_rails_...  (user_id => users.id)
#
class Annotation < ApplicationRecord
  include ApplicationHelper
  include Filterable

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
  validates :column, allow_nil: true, numericality: {
    greater_than_or_equal_to: 0
  }, if: ->(attr) { attr.column.present? }
  validates :columns, allow_nil: true, numericality: {
    greater_than_or_equal_to: 0
  }, if: ->(attr) { attr.columns.present? }
  validates :rows, numericality: {
    greater_than_or_equal_to: 1
  }, if: ->(attr) { attr.rows.present? }

  # Only allow responses if the annotation is not a response itself
  validates :thread_root_id, absence: true, if: -> { responses.any? }
  validates_associated :thread_root

  scope :by_submission, ->(submission_id) { where(submission_id: submission_id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :released, -> { left_joins(:evaluation).where(evaluation_id: nil).or(where(evaluations: { released: true })) }
  scope :by_username, ->(name) { where(user: User.by_filter(name)) }
  scope :by_exercise_name, ->(name) { where(submission: Submission.by_exercise_name(name)) }
  filterable_by :course_id, model: Course
  filterable_by :exercise_id, associations: :submission, column: 'submissions.exercise_id', model: Exercise

  scope :order_by_annotation_text, ->(direction) { reorder(annotation_text: direction) }
  scope :order_by_created_at, ->(direction) { reorder(created_at: direction) }

  before_validation :set_last_updated_by, on: :create
  before_validation :set_course_id, on: :create
  after_create :annotate_submission
  after_create :answer_previous_questions
  after_destroy :destroy_notification
  after_destroy :reset_submission_annotated
  after_save :create_notification

  scope :by_filter, lambda { |filter, skip_user:, skip_exercise:|
    filter.split.map(&:strip).compact_blank.map do |part|
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

  def previous_annotations
    return [] if thread_root.nil?

    [thread_root, thread_root&.responses&.where(created_at: ...created_at)].flatten
  end

  def answer_previous_questions
    previous_annotations.each do |previous_annotation|
      previous_annotation.update(question_state: :answered) if previous_annotation.is_a?(Question) && !previous_annotation.answered?
    end
  end
end
