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
class Question < Annotation
  include Filterable
  belongs_to :user, inverse_of: :questions
  counter_culture :user, column_name: proc { |question| question.answered? ? nil : 'open_questions_count' }

  after_save :schedule_reset_in_progress, if: :saved_change_to_question_state?
  after_commit :clear_transition

  filterable_by :question_state, is_enum: true
  enum :question_state, { unanswered: 0, in_progress: 1, answered: 2 }
  alias_attribute :question_text, :annotation_text

  # Used to authorize the transitions
  attr_accessor :transition_to, :transition_from

  def self.reset_in_progress(id)
    return unless exists?(id)

    question = find(id)
    return unless question.question_state == 'in_progress'

    question.update(question_state: 'unanswered')
  end

  def to_partial_path
    'annotations/annotation'
  end

  after_initialize do |question|
    question.question_state ||= 'unanswered'
  end

  # Disable notification creation & deletion
  def create_notification; end

  def destroy_notification; end

  def newer_submission
    # Submissions are sorted newest first by default
    Submission.where(id: (submission.id + 1).., exercise_id: submission.exercise_id, course_id: course_id, user_id: submission.user_id).first
  end

  private

  def clear_transition
    @transition_to = nil
    @transition_from = nil
  end

  def schedule_reset_in_progress
    return unless question_state == 'in_progress'

    Question.delay(run_at: 1.hour.from_now).reset_in_progress(id)
  end
end
