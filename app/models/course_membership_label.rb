# == Schema Information
#
# Table name: course_membership_labels
#
#  id                   :bigint           not null, primary key
#  course_label_id      :bigint           not null
#  course_membership_id :integer          not null
#
# Indexes
#
#  fk_rails_7d6a6611cf                       (course_membership_id)
#  unique_label_and_course_membership_index  (course_label_id,course_membership_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (course_label_id => course_labels.id) ON DELETE => cascade
#  fk_rails_...  (course_membership_id => course_memberships.id) ON DELETE => cascade
#

class CourseMembershipLabel < ApplicationRecord
  belongs_to :course_membership
  belongs_to :course_label
end
