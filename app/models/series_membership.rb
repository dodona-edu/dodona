# == Schema Information
#
# Table name: series_memberships
#
#  id          :integer          not null, primary key
#  series_id   :integer
#  activity_id :integer
#  order       :integer          default(999)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class SeriesMembership < ApplicationRecord
  belongs_to :series, counter_cache: :activities_count
  belongs_to :activity, counter_cache: :series_count

  delegate :course, to: :series

  default_scope { order(order: :asc, id: :asc) }

  validates :series_id, uniqueness: { scope: :activity_id }
  after_create :invalidate_caches
  after_create :add_activity_statuses_delayed
  after_destroy :invalidate_caches
  after_destroy :invalidate_status
  after_destroy :regenerate_activity_token

  def add_activity_statuses_delayed
    delay(queue: :statistics).add_activity_statuses
  end

  def add_activity_statuses
    if activity.is_a? Exercise
      activity.submissions.where(course: series.course).distinct(:user_id).find_each do |submission|
        ActivityStatus.create_or_find_by(series: series, activity: activity, user: submission.user)
      end
    else
      activity.activity_read_states.where(course: series.course).distinct(:user_id).find_each do |ars|
        ActivityStatus.create_or_find_by(series: series, activity: activity, user: ars.user)
      end
    end
  end

  def invalidate_caches
    course.invalidate_activities_count_cache
    series.touch
  end

  def invalidate_status
    ActivityStatus.delete_by(series: series, activity: activity)
  end

  def regenerate_activity_token
    activity.generate_access_token
    activity.save
  end
end
