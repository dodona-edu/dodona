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
#  users_correct   :integer
#  users_attempted :integer
#

class SeriesMembership < ApplicationRecord
  belongs_to :series
  belongs_to :exercise

  delegate :course, to: :series

  default_scope { order(order: :asc) }

  validates :series_id, uniqueness: { scope: :exercise_id }

  def cached_users_correct
    if users_correct.nil?
      self.users_correct = exercise.users_correct(course)
      save
    end
    users_correct
  end

  def cached_users_tried
    if users_attempted.nil?
      self.users_attempted = exercise.users_tried(course)
      save
    end
    users_attempted
  end

  def invalidate_stats_cache
    self.users_correct = nil
    self.users_attempted = nil
    save
  end
end
