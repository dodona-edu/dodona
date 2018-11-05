# == Schema Information
#
# Table name: series_memberships
#
#  id              :integer          not null, primary key
#  series_id       :integer
#  exercise_id     :integer
#  order           :integer          default(999)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class SeriesMembership < ApplicationRecord
  belongs_to :series
  belongs_to :exercise

  delegate :course, to: :series

  default_scope {order(order: :asc)}

  validates :series_id, uniqueness: {scope: :exercise_id}

  def cached_users_correct
    Rails.cache.fetch("/course/#{series.course_id}/exercise/#{exercise_id}/users_correct") do
      exercise.users_correct(course)
    end
  end

  def cached_users_tried
    Rails.cache.fetch("/course/#{series.course_id}/exercise/#{exercise_id}/users_tried") do
      exercise.users_tried(course)
    end
  end

  def invalidate_stats_cache
    Rails.cache.delete("/course/#{series.course_id}/exercise/#{exercise_id}/users_correct")
    Rails.cache.delete("/course/#{series.course_id}/exercise/#{exercise_id}/users_tried")
  end
end
