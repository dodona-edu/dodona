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
  belongs_to :series
  belongs_to :activity

  delegate :course, to: :series

  default_scope { order(order: :asc, id: :asc) }

  validates :series_id, uniqueness: { scope: :activity_id }
  after_create :invalidate_caches
  after_destroy :invalidate_caches
  after_destroy :regenerate_activity_token

  def invalidate_caches
    course.invalidate_activities_count_cache
  end

  def regenerate_activity_token
    activity.generate_access_token
    activity.save
  end
end
