require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers User, attrs: %i[username ugent_id first_name last_name email permission time_zone]

  setup do
    @instance = create(:zeus)
    sign_in @instance
  end

  test_crud_actions

  test 'should impersonate user' do
    other_user = create(:user)

    get impersonate_user_url(other_user)

    assert_redirected_to root_path
    assert_equal @controller.current_user, other_user
    assert_equal @controller.true_user, @instance

    get stop_impersonating_users_url

    assert_redirected_to root_path
    assert_equal @controller.current_user, @instance
    assert_equal @controller.true_user, @instance
  end

  test 'should get user photo' do
    get photo_user_url(@instance)
    assert_response :success
    assert_match %r{image\/(png|jpg|jpeg)}, response.content_type
  end

  test 'user token should log in' do
    sign_out :user
    token_user = create(:user_with_token)
    token = token_user.token

    get token_sign_in_user_url token_user, token: token

    assert_redirected_to root_path
    assert_equal @controller.current_user, token_user
  end

  test 'user index with course_id should be ok' do
    course = create(:course)
    get users_url(course_id: course.id)
    assert_response :success
  end
end
