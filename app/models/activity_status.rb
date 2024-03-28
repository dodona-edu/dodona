# == Schema Information
#
# Table name: activity_statuses
#
#  id                          :bigint           not null, primary key
#  accepted                    :boolean          default(FALSE), not null
#  accepted_before_deadline    :boolean          default(FALSE), not null
#  solved                      :boolean          default(FALSE), not null
#  started                     :boolean          default(FALSE), not null
#  solved_at                   :datetime
#  activity_id                 :integer          not null
#  series_id                   :integer
#  user_id                     :integer          not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  last_submission_id          :integer
#  last_submission_deadline_id :integer
#  best_submission_id          :integer
#  best_submission_deadline_id :integer
#  series_id_non_nil           :integer          not null
#
class ActivityStatus < ApplicationRecord
  # the reverse relations aren't defined because this doesn't make sense and there are no
  # indexes defined to allow fast retrieval
  belongs_to :last_submission, class_name: 'Submission', optional: true
  belongs_to :last_submission_deadline, class_name: 'Submission', optional: true
  belongs_to :best_submission, class_name: 'Submission', optional: true
  belongs_to :best_submission_deadline, class_name: 'Submission', optional: true

  belongs_to :activity
  belongs_to :series, optional: true
  belongs_to :user

  validates :series_id_non_nil, uniqueness: { scope: %i[user_id activity_id] }, on: :create

  scope :in_series, ->(series) { where(series: series) }
  scope :for_user, ->(user) { where(user: user) }

  before_validation :initialise_series_id_non_nil, if: -> { new_record? }
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

  def self.add_status_for_series(series, eager = [])
    Current.status_store ||= {}
    ActivityStatus.where(series: series).unscope(:order).includes(eager).find_each do |as|
      Current.status_store[[as.user_id, as.series_id, as.activity_id]] = as
    end
  end

  def self.add_status_for_user_and_series(user, series, eager = [])
    Current.status_store ||= {}
    ActivityStatus.where(series: series, user: user).unscope(:order).includes(eager).find_each do |as|
      Current.status_store[[as.user_id, as.series_id, as.activity_id]] = as
    end
  end

  def self.add_status_for_user_and_activities(user, activities, eager = [])
    Current.status_store ||= {}
    ActivityStatus.where(activity: activities, user: user, series: nil).unscope(:order).includes(eager).find_each do |as|
      Current.status_store[[as.user_id, nil, as.activity_id]] = as
    end
  end

  def self.clear_status_store
    Current.status_store = {}
  end

  private

  def initialise_series_id_non_nil
    self.series_id_non_nil = series_id || 0
  end

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

    last = activity.last_submission!(user, nil, series&.course)
    last_before_deadline = activity.last_submission!(user, series&.deadline, series&.course) if last
    best = activity.best_submission!(user, nil, series&.course) if last
    best_before_deadline = activity.best_submission!(user, series&.deadline, series&.course) if best

    self.last_submission = last
    self.last_submission_deadline = last_before_deadline
    self.best_submission = best
    self.best_submission_deadline = best_before_deadline

    self.accepted = last&.accepted? || false
    self.accepted_before_deadline = last_before_deadline&.accepted? || false
    self.solved = best&.accepted? || false
    if solved?
      self.solved_at = best_before_deadline&.accepted? ? best_before_deadline&.created_at : best&.created_at
    end
    self.started = last.present?
  end
end
