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
# Indexes
#
#  index_course_memberships_on_course_id              (course_id)
#  index_course_memberships_on_user_id                (user_id)
#  index_course_memberships_on_user_id_and_course_id  (user_id,course_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (course_id => courses.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#

require 'test_helper'

class CourseMembershipTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
