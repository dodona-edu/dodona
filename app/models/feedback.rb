# == Schema Information
#
# Table name: feedbacks
#
#  id                     :bigint           not null, primary key
#  submission_id          :integer
#  evaluation_id          :bigint
#  evaluation_user_id     :bigint
#  evaluation_exercise_id :bigint
#  completed              :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class Feedback < ApplicationRecord
  include ActiveModel::Dirty

  belongs_to :evaluation
  belongs_to :evaluation_user
  belongs_to :evaluation_exercise
  belongs_to :submission, optional: true

  has_many :scores, dependent: :destroy
  has_many :score_items, through: :evaluation_exercise

  delegate :user, to: :evaluation_user
  delegate :exercise, to: :evaluation_exercise

  before_save :uncomplete, if: :will_save_change_to_submission_id?
  before_save :reset_feedback_after_submission_update
  before_create :generate_id
  before_create :determine_submission
  after_create :set_blank_to_zero
  before_destroy :destroy_related_annotations

  validate :submission_user_exercise_correct

  accepts_nested_attributes_for :scores

  scope :complete, -> { where(completed: true) }
  scope :incomplete, -> { where(completed: false) }

  scope :decided, -> { where.not(submission: nil) }
  scope :undecided, -> { where(submission: nil) }

  def previous_attempts
    user.submissions.of_exercise(exercise).in_course(evaluation.series.course).before_deadline(submission.created_at).count
  end

  def later_attempts
    user.submissions.of_exercise(exercise).in_course(evaluation.series.course).where('created_at > ?', submission.created_at).count
  end

  def total_attempts
    user.submissions.of_exercise(exercise).in_course(evaluation.series.course).count
  end

  def time_to_deadline
    {
      deadline: submission.exercise.series.find_by(course: submission.course).deadline,
      submission_time: submission.created_at
    }
  end

  def siblings
    feedbacks_same_exercise = evaluation.feedbacks.where(evaluation_exercise: evaluation_exercise).order(:id)

    {
      next: feedbacks_same_exercise.find_by('id > ?', id) || feedbacks_same_exercise.first,
      # We use id < self.id here for the cycle because we could otherwise find ourselves.
      next_unseen: feedbacks_same_exercise.incomplete.find_by('id > ?', id) || feedbacks_same_exercise.incomplete.find_by('id < ?', id)
    }
  end

  def done_grading?
    score_items.count == scores.count
  end

  def score
    mapped = scores.map(&:score)
    mapped.sum if mapped.any?
  end

  def maximum_score
    mapped = score_items.map(&:maximum)
    mapped.sum if mapped.any?
  end

  def user_labels
    evaluation
      .series
      .course
      .course_memberships
      .find_by(user_id: user)
      .course_labels
  end

  private

  def determine_submission
    # First because the default order is id: :desc
    self.submission = user.submissions.in_course(evaluation.series.course).of_exercise(exercise).before_deadline(evaluation.deadline).first
    self.completed = true if submission.nil?
  end

  def generate_id
    begin
      new = SecureRandom.random_number(2_147_483_646)
    end until Feedback.find_by(id: new).nil?
    self.id = new
  end

  def uncomplete
    self.completed = false
  end

  def reset_feedback_after_submission_update
    return unless will_save_change_to_submission_id?

    Submission.find(submission_id_in_database).annotations.where(evaluation_id: evaluation_id).destroy_all if submission_id_in_database.present?
    scores.each(&:destroy)
  end

  def destroy_related_annotations
    submission.annotations.where(evaluation_id: evaluation_id).destroy_all if submission.present?
  end

  def submission_user_exercise_correct
    errors.add(:submission, 'user should be the same as in the evaluation') if submission.present? && submission.user_id != user.id
    errors.add(:submission, 'exercise should be the same as in the evaluation') if submission.present? && submission.exercise_id != exercise.id
    errors.add(:submission, 'course should be the same as in the evaluation') if submission.present? && submission.course_id != evaluation.series.course_id
  end

  def set_blank_to_zero
    return if submission.present?

    score_items.each do |score_item|
      Score.create(score_item: score_item, feedback: self, score: 0, last_updated_by: Current.user)
    end
  end
end
