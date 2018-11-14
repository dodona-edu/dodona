# == Schema Information
#
# Table name: course_memberships
#
#  id         :integer          not null, primary key
#  course_id  :integer
#  user_id    :integer
#  status     :integer          default("student")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  favorite   :boolean          default(FALSE)
#

class CourseMembership < ApplicationRecord
  enum status: %i[pending course_admin student unsubscribed]

  belongs_to :course
  belongs_to :user
  has_many :course_membership_labels
  has_many :course_labels, through: :course_membership_labels

  validates :course_id, uniqueness: {scope: :user_id}

  validate :at_least_one_admin_per_course

  before_create {self.status ||= :student}
  after_update :invalidate_caches
  before_destroy :invalidate_caches

  def at_least_one_admin_per_course
    if status_was == 'course_admin' &&
        status != 'course_admin' &&
        CourseMembership
            .where(course: course, status: :course_admin)
            .where.not(id: id).empty?
      errors.add(:status, :at_least_one_admin_per_course)
    end
  end

  def invalidate_caches
    course.invalidate_subscribed_members_count_cache
  end
end
