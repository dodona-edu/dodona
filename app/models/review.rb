# == Schema Information
#
# Table name: reviews
#
#  id                 :bigint           not null, primary key
#  submission_id      :integer
#  review_session_id  :bigint
#  user_id            :integer
#  review_exercise_id :bigint
#  completed          :boolean          default(FALSE), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
class Review < ApplicationRecord
  belongs_to :review_session
  belongs_to :user
  belongs_to :review_exercise
  belongs_to :submission, optional: true

  scope :complete, -> { where(completed: true) }
  scope :incomplete, -> { where(completed: false) }

  scope :decided, -> { where.not(submission: nil) }
  scope :undecided, -> { where(submission: nil) }

  validates :review_session_id, presence: true
  validates :user_id, presence: true
  validates :review_exercise_id, presence: true

  before_save :determine_submission
  before_destroy :unset_annotation_references

  def determine_submission
    # First because the default order is id: :desc
    self.submission = user.submissions.of_exercise(review_exercise.exercise).judged.before_deadline(review_session.deadline).first
  end

  def previous_attempts
    [user.submissions.of_exercise(review_exercise.exercise).before_deadline(submission.created_at).count - 1, 0].max
  end

  def session_metadata
    review_session.metadata(self)
  end

  def time_to_deadline
    {
      deadline: submission.exercise.series.find_by(course: submission.course).deadline,
      submission_time: submission.created_at
    }
  end

  private

  def unset_annotation_references
    submission&.annotations&.each do |annotation|
      annotation.review_session = nil
    end
  end
end
