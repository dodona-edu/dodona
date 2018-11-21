# == Schema Information
#
# Table name: series_memberships
#
#  id          :integer          not null, primary key
#  series_id   :integer
#  exercise_id :integer
#  order       :integer          default(999)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class SeriesMembership < ApplicationRecord
  belongs_to :series
  belongs_to :exercise

  delegate :course, to: :series

  default_scope {order(order: :asc)}

  validates :series_id, uniqueness: {scope: :exercise_id}
  after_update :invalidate_caches
  before_destroy :invalidate_caches

  def invalidate_caches
    course.invalidate_exercises_count_cache
  end
end
