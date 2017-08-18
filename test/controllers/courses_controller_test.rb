require 'helpers/crud_helper'
require 'test_helper'

class CoursesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Course, attrs: %i[name year description]

  setup do
    @instance = create(:course)
    sign_in create(:zeus)
  end

  test_crud_actions

  test 'should get scoresheet' do
    get scoresheet_course_path(@instance)
    assert_response :success
  end

  test 'should subscribe current_user to course' do
    user = create :user
    sign_in user
    post subscribe_course_path(@instance)
    assert @instance.users.include? user
  end

  test 'subscribe should redirect to course' do
    post subscribe_course_path(@instance)
    assert_redirected_to(@instance)
  end

  test 'should subscribe current_user to course with secret' do
    user = create :user
    sign_in user
    get subscribe_with_secret_course_path(@instance, @instance.secret)
    assert @instance.users.include? user
  end

  test 'should not subscibe when already subscribed' do
    user = create :user, courses: [@instance]
    sign_in user
    assert_difference('CourseMembership.count', 0) do
      post subscribe_course_path(@instance)
    end
  end

  test 'subscribe with secret should redirect to course' do
    get subscribe_with_secret_course_path(@instance, @instance.secret)
    assert_redirected_to(@instance)
  end

  test 'should not subscibe with secret when already subscribed' do
    user = create :user, courses: [@instance]
    sign_in user
    assert_difference('CourseMembership.count', 0) do
      get subscribe_with_secret_course_path(@instance, @instance.secret)
    end
  end

  test 'should not subscribe current_user to course with invalid secret' do
    user = create :user
    sign_in user
    get subscribe_with_secret_course_path(@instance, 'the cake is a lie')
    assert !@instance.users.include?(user)
  end
end
