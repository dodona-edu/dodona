# == Schema Information
#
# Table name: activity_statuses
#
#  id                       :bigint           not null, primary key
#  accepted                 :boolean          default(FALSE), not null
#  accepted_before_deadline :boolean          default(FALSE), not null
#  solved                   :boolean          default(FALSE), not null
#  started                  :boolean          default(FALSE), not null
#  solved_at                :datetime
#  activity_id              :integer          not null
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

  before_create :initialise_values_for_content_page, if: -> { activity.content_page? }
  before_create :initialise_values_for_exercise, if: -> { activity.exercise? }

  def best_is_last?
    accepted == solved
  end

  def wrong?
    started && !accepted?
  end

  def update_values
    initialise_values_for_content_page
    initialise_values_for_exercise
    save
  end

  private

  def initialise_values_for_content_page
    return unless activity.content_page?

    read_state = activity.read_state_for(user, series&.course)
    return if read_state.blank?

    self.accepted = true
    self.accepted_before_deadline = series&.deadline? ? read_state.created_at.before?(series.deadline) : true
    self.solved = true
    self.solved_at = read_state.created_at
    self.started = true
  end

  def initialise_values_for_exercise
    return unless activity.exercise?

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
