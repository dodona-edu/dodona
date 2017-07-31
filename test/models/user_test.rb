# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  username   :string(255)
#  ugent_id   :string(255)
#  first_name :string(255)
#  last_name  :string(255)
#  email      :string(255)
#  permission :integer          default("student")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  lang       :string(255)      default("nl")
#  token      :string(255)
#  time_zone  :string(255)      default("Brussels")
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'factory should create user' do
    create :user
  end

  test 'user without username should have token' do
    user = create :user, username: nil
    assert_not_nil user.token
  end

  test 'user with username should not have a token' do
    user = create :user
    assert_nil user.token
  end

  test 'user timezone should be set' do
    user_brussels = create :user
    assert_equal user_brussels.time_zone, 'Brussels'

    user_korea = create :user, email: 'hupseflupse@ghent.ac.kr'
    assert_equal user_korea.time_zone, 'Seoul'
  end

  test 'header courses for user' do
    user = create :user, courses: []
    assert_nil user.header_courses

    user.courses << create_list(:course, 5)
    header = user.header_courses
    assert_equal header.length, 3
  end

  test 'cas_extra_attributes should be set' do
    user = create(:user)
    attrs = {
      mail: 'mertens.ron@gmail.com',
      givenname: 'Ron',
      surname: 'Mertens',
      ugentID: 23_456_789
    }
    user.cas_extra_attribtues = attrs
    attrs.each do |attr_name, value|
      assert_equals value, user.send(attr_name)
    end
  end
end
