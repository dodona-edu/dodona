require 'test_helper'
class ApplicationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = create :course, visibility: :hidden, registration: :closed
    @user = create :student
  end

  test 'should store last location' do
    location = root_path params: { foo: 'bar' }
    get location
    assert_response :success
    assert_equal session[:user_return_to], location
  end

  test 'should not store last location if too big' do
    location = root_path params: { foo: "b#{'a' * 1024}r" }
    get location
    assert_response :success
    assert_not_equal session[:user_return_to], location
    assert session[:user_return_to].length < 100
  end

  test 'should get unauthorized status when not logged in' do
    get course_url(@course, format: :json)
    assert_response :unauthorized
  end

  test 'should get forbidden status when logged in but not authorized' do
    sign_in @user
    get course_url(@course, format: :json)
    assert_response :forbidden
  end

  test 'page zero should return page one' do
    sign_in @user
    get courses_path(page: 0)
    assert_response :ok
  end
end
