# == Schema Information
#
# Table name: reviews
#
#  id                 :bigint           not null, primary key
#  submission_id      :integer
#  review_session_id  :bigint
#  review_user_id     :bigint
#  review_exercise_id :bigint
#  completed          :boolean          default(FALSE), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
class Review < ApplicationRecord
  include ActiveModel::Dirty

  belongs_to :review_session
  belongs_to :review_user
  belongs_to :review_exercise
  belongs_to :submission, optional: true

  before_create :determine_submission
  before_destroy :destroy_related_annotations
  before_save :manage_annotations_after_submission_update

  validate :submission_user_exercise_correct

  scope :complete, -> { where(completed: true) }
  scope :incomplete, -> { where(completed: false) }

  scope :decided, -> { where.not(submission: nil) }
  scope :undecided, -> { where(submission: nil) }

  def determine_submission
    # First because the default order is id: :desc
    self.submission = review_user.user.submissions.of_exercise(review_exercise.exercise).before_deadline(review_session.deadline).first
  end

  def previous_attempts
    [review_user.user.submissions.of_exercise(review_exercise.exercise).before_deadline(submission.created_at).count - 1, 0].max
  end

  def session_metadata
    incompleted = review_session.reviews.incomplete
    {
      exercise_remaining: incompleted.where(review_exercise: review_exercise).count,
      user_remaining: incompleted.where(review_user: review_user).count,
      remaining: incompleted.count,
      total: review_session.reviews.count
    }
  end

  def time_to_deadline
    {
      deadline: submission.exercise.series.find_by(course: submission.course).deadline,
      submission_time: submission.created_at
    }
  end

  def siblings
    others = review_session.reviews
    reviews_same_exercise = others.where(review_exercise: review_exercise).order(:id)
    reviews_same_user = others.where(review_user: review_user).order(:id)

    {
      id: {
        prev: others.where('id < ?', id).last,
        next: others.find_by('id > ?', id)
      },
      exercise: {
        prev: reviews_same_exercise.where('id < ?', id).last,
        next: reviews_same_exercise.find_by('id > ?', id)
      },
      user: {
        prev: reviews_same_user.where('id < ?', id).last,
        next: reviews_same_user.find_by('id > ?', id)
      }
    }
  end

  private

  def manage_annotations_after_submission_update
    return unless submission_id_changed? && submission_id_was.present?

    Submission.find(submission_id_was).annotations.where(review_session_id: review_session_id).destroy_all
  end

  def destroy_related_annotations
    submission.annotations.where(review_session_id: review_session_id).destroy_all if submission.present?
  end

  def submission_user_exercise_correct
    errors.add(:submission, 'user should be the same as in the review') if submission.present? && submission.user_id != review_user.user_id
    errors.add(:submission, 'exercise should be the same as in the review') if submission.present? && submission.exercise_id != review_exercise.exercise_id
  end
end
