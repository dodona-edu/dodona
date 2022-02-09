require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers User, attrs: %i[username first_name last_name email permission time_zone]

  setup do
    @instance = users(:zeus)
    sign_in @instance
  end

  test_crud_actions

  test 'staff should not be able to make themself zeus' do
    sign_out :user

    staff = users(:staff)
    sign_in staff

    put user_url(staff), params: { user: { permission: :zeus } }

    assert_not staff.reload.zeus?
  end

  test 'json representation should contain courses' do
    # create distractions
    other_user = users(:student)
    create(:course, subscribed_members: [other_user])

    # actual course to test against
    create(:course, subscribed_members: [@instance, other_user])

    get user_url(@instance, format: :json)

    assert_response :success
    user_json = JSON.parse(response.body)
    assert user_json.key?('subscribed_courses')

    course_ids = user_json['subscribed_courses'].map { |c| c['id'] }

    # check if each course in the result actually belongs to the user
    course_ids.each do |cid|
      c = Course.find(cid)
      assert @instance.subscribed_courses.include?(c), "should not contain #{c}"
    end

    # this should catch the case where there are less courses returned
    assert_equal @instance.subscribed_courses.count, user_json['subscribed_courses'].count, 'unexpected amount of courses for this user'
  end

  test 'should impersonate user' do
    other_user = users(:student)

    get impersonate_user_url(other_user)

    assert_redirected_to root_path
    assert_equal @controller.current_user, other_user
    assert_equal @controller.true_user, @instance

    get stop_impersonating_users_url

    assert_redirected_to root_path
    assert_equal @controller.current_user, @instance
    assert_equal @controller.true_user, @instance
  end

  test 'user token should log in' do
    sign_out :user
    token_user = create :user, institution: nil
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

  test 'normal user should not be allowed to view other user profile' do
    sign_out :user
    sign_in users(:student)

    get user_url(@instance)

    assert_redirected_to root_path
    assert_equal flash[:alert], I18n.t('errors.no_rights')
  end

  test 'not logged in should be redirected to login page when unauthorized' do
    sign_out :user
    get user_url(@instance)

    assert_redirected_to sign_in_path
  end

  test 'should render edit page for staff' do
    user = users(:staff)
    sign_in user
    get edit_user_url(user)

    assert_response :success
  end
end
