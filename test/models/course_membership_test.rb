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

require 'test_helper'

class CourseMembershipTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
