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

require 'test_helper'

class CourseMembershipTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
