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

  delegate :user, to: :evaluation_user
  delegate :exercise, to: :evaluation_exercise

  before_save :manage_annotations_after_submission_update
  before_create :generate_id
  before_create :determine_submission
  before_destroy :destroy_related_annotations

  validate :submission_user_exercise_correct

  scope :complete, -> { where(completed: true) }
  scope :incomplete, -> { where(completed: false) }

  scope :decided, -> { where.not(submission: nil) }
  scope :undecided, -> { where(submission: nil) }

  def previous_attempts
    user.submissions.of_activity(exercise).in_course(evaluation.series.course).before_deadline(submission.created_at).count
  end

  def later_attempts
    user.submissions.of_activity(exercise).in_course(evaluation.series.course).where('created_at > ?', submission.created_at).count
  end

  def total_attempts
    user.submissions.of_activity(exercise).in_course(evaluation.series.course).count
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

  private

  def determine_submission
    # First because the default order is id: :desc
    self.submission = user.submissions.of_activity(exercise).before_deadline(evaluation.deadline).first
    self.completed = true if submission.nil?
  end

  def generate_id
    begin
      new = SecureRandom.random_number(2_147_483_646)
    end until Feedback.find_by(id: new).nil?
    self.id = new
  end

  def manage_annotations_after_submission_update
    return unless submission_id_changed? && submission_id_was.present?

    Submission.find(submission_id_was).annotations.where(evaluation_id: evaluation_id).destroy_all
  end

  def destroy_related_annotations
    submission.annotations.where(evaluation_id: evaluation_id).destroy_all if submission.present?
  end

  def submission_user_exercise_correct
    errors.add(:submission, 'user should be the same as in the evaluation') if submission.present? && submission.user_id != user.id
    errors.add(:submission, 'exercise should be the same as in the evaluation') if submission.present? && submission.activity_id != exercise.id
  end
end
