# == Schema Information
#
# Table name: course_memberships
#
#  id         :integer          not null, primary key
#  course_id  :integer
#  user_id    :integer
#  status     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CourseMembership < ApplicationRecord
  enum status: %i[pending course_admin student]

  belongs_to :course
  belongs_to :user

  validates :course_id, uniqueness: { scope: :user_id }

  before_create { self.status ||= :student }
  after_create :invalidate_stats_cache

  def invalidate_stats_cache
    SeriesMembership.where(series_id: course.series).find_each(&:invalidate_stats_cache)
  end
end
