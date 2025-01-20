# == Schema Information
#
# Table name: course_labels
#
#  id         :bigint           not null, primary key
#  course_id  :integer          not null
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CourseLabel < ApplicationRecord
  belongs_to :course
  has_many :course_membership_labels, dependent: :restrict_with_error
  has_many :course_memberships, through: :course_membership_labels

  before_save :downcase_name

  private

  def downcase_name
    name.downcase!
  end
end
