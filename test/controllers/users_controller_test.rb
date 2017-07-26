require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, permission: :zeus)
    sign_in @user
  end

  test 'should get index' do
    get users_url(:nl)
    assert_response :success
  end

  test 'should get new' do
    get new_user_url
    assert_response :success
  end

  test 'should create user' do
    assert_difference('User.count') do
      post users_url, params: { user: {} }
    end

    assert_redirected_to user_path(User.last)
  end

  test 'should show user' do
    get user_url(@user)
    assert_response :success
  end

  test 'should get edit' do
    get edit_user_url(@user)
    assert_response :success
  end

  test 'should update user' do
    patch user_url(@user), params: { user: {} }
    assert_redirected_to user_path(@user)
  end

  test 'should destroy user' do
    assert_difference('User.count', -1) do
      delete user_url(:en, @user)
    end

    assert_redirected_to users_path
  end
end
