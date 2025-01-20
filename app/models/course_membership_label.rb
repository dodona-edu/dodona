# == Schema Information
#
# Table name: course_membership_labels
#
#  id                   :bigint           not null, primary key
#  course_label_id      :bigint           not null
#  course_membership_id :integer          not null
#

class CourseMembershipLabel < ApplicationRecord
  belongs_to :course_membership
  belongs_to :course_label
end
