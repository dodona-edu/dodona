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
class ActivityStatus < ApplicationRecord
  belongs_to :activity
  belongs_to :series, optional: true
  belongs_to :user

  scope :in_series, ->(series) { where(series: series) }
  scope :for_user, ->(user) { where(user: user) }

  before_create :initialise_values

  def best_is_last?
    accepted == solved
  end

  def wrong?
    started && !accepted?
  end

  def update_values
    initialise_values
    save
  end

  private

  def initialise_values
    best = activity.best_submission(user, nil, series&.course)
    best_before_deadline = activity.best_submission(user, series&.deadline, series&.course)
    last = activity.last_submission(user, nil, series&.course)
    last_before_deadline = activity.last_submission(user, series&.deadline, series&.course)

    self.accepted = last&.accepted? || false
    self.accepted_before_deadline = last_before_deadline&.accepted? || false
    self.solved = best&.accepted? || false
    if solved?
      self.solved_at = best_before_deadline&.accepted? ? best_before_deadline&.created_at : best&.created_at
    end
    self.started = last.present?
  end
end
