# == Schema Information
#
# Table name: users
#
#  id             :integer          not null, primary key
#  username       :string(255)
#  ugent_id       :string(255)
#  first_name     :string(255)
#  last_name      :string(255)
#  email          :string(255)
#  permission     :integer          default("student")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  lang           :string(255)      default("nl")
#  token          :string(255)
#  time_zone      :string(255)      default("Brussels")
#  institution_id :integer
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'factory should create user' do
    assert_not_nil create(:user)
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

  test 'recent courses for user' do
    user = create :user, courses: []
    assert_equal [], user.recent_courses(2)

    user.courses << create_list(:course, 5)
    courses = user.recent_courses(2)
    assert_not_equal [], courses

    courses = user.recent_courses(1)
    assert_not_equal [], courses
  end

  test 'only zeus and staff should be admin' do
    assert create(:zeus).admin?
    assert create(:staff).admin?
    assert_not create(:user).admin?
  end

  test 'only zeus should always be course admin' do
    assert create(:zeus).course_admin? nil
    assert_not create(:staff).course_admin? nil
    assert_not create(:user).course_admin? nil
  end

  test 'user and staff can be course admin' do
    user = create(:user)
    staff = create(:staff)
    zeus = create(:zeus)

    course = create(:course)

    assert_not user.course_admin?(course)
    assert_not staff.course_admin?(course)
    assert zeus.course_admin?(course)

    course.users.push(user, staff, zeus)

    assert_not user.course_admin?(course)
    assert_not staff.course_admin?(course)
    assert zeus.course_admin?(course)

    user.course_memberships.first.update(status: 'course_admin')
    staff.course_memberships.first.update(status: 'course_admin')
    zeus.course_memberships.first.update(status: 'course_admin')

    assert user.course_admin?(course)
    assert staff.course_admin?(course)
    assert zeus.course_admin?(course)
  end

  test 'full name should be n/a when blank' do
    user = create(:user, first_name: nil, last_name: nil)
    assert_equal 'n/a', user.full_name

    user.first_name = ' '
    assert_equal 'n/a', user.full_name

    user.last_name = "\t"
    assert_equal 'n/a', user.full_name

    user.first_name = 'herp'
    user.last_name = 'derp'
    assert_equal 'herp derp', user.full_name
  end

  test 'short name should not be nil' do
    user = create(:user)
    assert_equal user.username, user.short_name

    user.username = nil
    assert_equal user.first_name, user.short_name

    user.first_name = nil
    assert_equal ' ' + user.last_name, user.short_name

    user.last_name = nil
    assert_equal 'n/a', user.short_name
  end

  test 'user member_off should tell whether he is in a course or not' do
    user1 = create(:user)
    user2 = create(:user)

    course1 = create(:course)
    course2 = create(:course)

    user1.courses << course1
    user2.courses << course2

    assert user1.member_of? course1
    assert user2.member_of? course2
    assert_not user1.member_of? course2
    assert_not user2.member_of? course1
  end

  def assert_user_exercises(user, attempted, correct, unfinished)
    assert_equal attempted, user.attempted_exercises, 'wrong amount of attempted exercises'
    assert_equal correct, user.correct_exercises, 'wrong amount of correct exercises'
    assert_equal unfinished, user.unfinished_exercises, 'wrong amount of unfinished exercises'
  end

  test 'user should have correct number of attempted, unfinished and correct exercises' do
    user = create :user
    exercise1 = create :exercise
    exercise2 = create :exercise
    exercise3 = create :exercise
    create :exercise

    assert_user_exercises user, 0, 0, 0

    create :wrong_submission, user: user, exercise: exercise1
    create :wrong_submission, user: user, exercise: exercise1
    create :wrong_submission, user: user, exercise: exercise1
    assert_user_exercises user, 1, 0, 1

    create :correct_submission, user: user, exercise: exercise1
    create :correct_submission, user: user, exercise: exercise1
    assert_user_exercises user, 1, 1, 0

    create :correct_submission, user: user, exercise: exercise2
    assert_user_exercises user, 2, 2, 0

    create :wrong_submission, user: user, exercise: exercise3
    assert_user_exercises user, 3, 2, 1
  end

  test 'only smartschool users can have blank email' do
    smartschool = create :smartschool_institution
    office365 = create :office365_institution
    saml = create :saml_institution

    user = build :user, institution: office365
    user.email = nil
    assert_not user.valid?

    user = build :user, institution: saml
    user.email = nil
    assert_not user.valid?

    user = build :user, institution: nil
    user.email = nil
    assert_not user.valid?

    user = build :user, institution: smartschool
    user.email = nil
    assert user.valid?

    user = build :user, institution: smartschool
    user.email = nil
    assert user.valid?
  end
end
