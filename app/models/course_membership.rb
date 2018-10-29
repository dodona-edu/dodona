# == Schema Information
#
# Table name: course_memberships
#
#  id         :integer          not null, primary key
#  course_id  :integer
#  user_id    :integer
#  status     :integer          default("student")
#  favorite   :boolean          default(false)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CourseMembership < ApplicationRecord
  enum status: %i[pending course_admin student unsubscribed]

  belongs_to :course
  belongs_to :user

  validates :course_id, uniqueness: {scope: :user_id}

  validate :at_least_one_admin_per_course

  before_create {self.status ||= :student}
  after_create :invalidate_stats_cache

  def invalidate_stats_cache
    SeriesMembership.where(series_id: course.series).find_each(&:invalidate_stats_cache)
  end

  def at_least_one_admin_per_course
    if status_was == 'course_admin' &&
        status != 'course_admin' &&
        CourseMembership
            .where(course: course, status: :course_admin)
            .where.not(id: id).empty?
      errors.add(:status, :at_least_one_admin_per_course)
    end
  end
end
