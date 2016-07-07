# == Schema Information
#
# Table name: courses
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  year       :string(255)
#  secret     :string(255)
#  open       :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Course < ApplicationRecord
  has_many :course_memberships
  has_many :users, through: :course_memberships
end
