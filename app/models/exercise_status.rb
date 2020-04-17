# == Schema Information
#
# Table name: exercise_statuses
#
#  id                       :bigint           not null, primary key
#  accepted                 :boolean          default(FALSE), not null
#  accepted_before_deadline :boolean          default(FALSE), not null
#  solved                   :boolean          default(FALSE), not null
#  started                  :boolean          default(FALSE), not null
#  solved_at                :datetime
#  exercise_id              :integer          not null
#  series_id                :integer
#  user_id                  :integer          not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
class ExerciseStatus < ApplicationRecord
  belongs_to :exercise
  belongs_to :series, optional: true
  belongs_to :user

  scope :in_series, ->(series) { where(series: series) }
  scope :for_exercise, ->(exercise) { where(exercise: exercise) }
  scope :for_user, ->(user) { where(user: user) }

  before_create :initialise_values

  def best_is_last?
    accepted == solved
  end

  def wrong?
    started && !accepted?
  end

  def update_values(submission)
    updates = { accepted: submission.accepted?, started: true }
    updates[:accepted_before_deadline] = submission.accepted? if series.blank? || series&.deadline&.future?
    updates[:solved] = solved || submission.accepted?
    updates[:solved_at] = submission.created_at if submission.accepted? && !solved

    update updates
  end

  private

  def initialise_values
    best = exercise.best_submission(user, nil, series&.course)
    best_before_deadline = exercise.best_submission(user, series&.deadline, series&.course)
    last = exercise.last_submission(user, nil, series&.course)
    last_before_deadline = exercise.last_submission(user, series&.deadline, series&.course)

    self.accepted = last&.accepted? || false
    self.accepted_before_deadline = last_before_deadline&.accepted? || false
    self.solved = best&.accepted? || false
    if solved?
      self.solved_at = best_before_deadline&.accepted? ? best_before_deadline&.created_at : best&.created_at
    end
    self.started = last.present?
  end
end
