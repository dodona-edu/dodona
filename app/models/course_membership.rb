# == Schema Information
#
# Table name: course_memberships
#
#  id         :integer          not null, primary key
#  favorite   :boolean          default(FALSE)
#  status     :integer          default("student"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  course_id  :integer          not null
#  user_id    :integer          not null
#

class CourseMembership < ApplicationRecord
  include Filterable
  enum :status, { pending: 0, course_admin: 1, student: 2, unsubscribed: 3 }

  belongs_to :course
  belongs_to :user
  has_many :course_membership_labels, dependent: :destroy
  has_many :course_labels, through: :course_membership_labels

  validates :course_id, uniqueness: { scope: :user_id }

  validate :at_least_one_admin_per_course

  before_create { self.status ||= :student }
  after_destroy :invalidate_caches
  after_save :invalidate_caches
  after_save :delete_unused_course_labels

  scope :by_permission, ->(permission) { where(user: User.by_permission(permission)) }
  scope :by_filter, ->(filter) { where(user: User.by_filter(filter)) }
  filterable_by :course_labels, associations: :course_labels, column: 'course_labels.name', multi: true
  filterable_by :institution_id, associations: { user: [:institution] }, column: 'institutions.id', model: Institution

  scope :order_by_status_in_course_and_name, ->(direction) { joins(:user).merge(User.order_by_status_in_course_and_name(direction)) }
  scope :order_by_progress, ->(direction, course) { joins(:user).merge(User.order_by_progress(direction, course)) }

  def subscribed?
    student? || course_admin?
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

  def invalidate_caches
    course.invalidate_subscribed_members_count_cache
  end

  def delete_unused_course_labels
    CourseLabel.includes(:course_membership_labels)
               .where(course_membership_labels: { course_label_id: nil })
               .destroy_all
  end
end
