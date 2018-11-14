# == Schema Information
#
# Table name: course_membership_labels
#
#  id                   :bigint(8)        not null, primary key
#  course_membership_id :integer          not null
#  course_label_id      :bigint(8)        not null
#

class CourseMembershipLabel < ApplicationRecord
  belongs_to :course_membership
  belongs_to :course_label
  after_destroy :delete_unused_course_labels

  def delete_unused_course_labels
    CourseLabel.includes(:course_membership_labels)
        .where(:course_membership_labels => {:course_label_id => nil})
        .destroy_all
  end
end
