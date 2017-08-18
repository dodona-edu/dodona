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
    get scoresheet_course_url(@instance)
    assert_response :success
  end

  test 'should subscribe current_user to course' do
    user = create :user
    sign_in user
    post subscribe_course_url(@instance)
    assert @instance.users.include? user
  end

  test 'subscribe should redirect to course' do
    post subscribe_course_url(@instance)
    assert_redirected_to(@instance)
  end

  test 'should get registration page with secret' do
    user = create :user
    sign_in user
    %w[visible hidden].product(%w[open moderated closed]).each do |v, r|
      @instance.update(visibility: v, registration: r)
      get registration_course_url(@instance, @instance.secret)
      assert_response :success
      # GET should not subscribe
      assert_not user.member_of?(@instance)
    end
  end

  test 'should not subscibe when already subscribed' do
    user = create :user, courses: [@instance]
    sign_in user
    assert_difference('CourseMembership.count', 0) do
      post subscribe_course_url(@instance)
    end
  end

  test 'visiting registration page when subscribed should redirect' do
    user = create :user, courses: [@instance]
    sign_in user
    get registration_course_url(@instance, @instance.secret)
    assert_redirected_to @instance
  end

  test 'should not subscribe to hidden course with invalid, empty or absent secret' do
    user = create :user
    sign_in user
    @instance.update(visibility: 'hidden')
    post subscribe_course_url(@instance, token: 'the cake is a lie')
    assert !@instance.users.include?(user), 'invalid token'

    post subscribe_course_url(@instance, token: '')
    assert !@instance.users.include?(user), 'empty token'

    post subscribe_course_url(@instance)
    assert !@instance.users.include?(user), 'absent token'
  end
end
