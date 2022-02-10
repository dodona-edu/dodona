require 'test_helper'

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    user = users(:student)
    sign_in user
    @notification = create :notification, user: user
  end

  test 'should get index' do
    get notifications_url(format: :json)
    assert_response :success
  end

  test 'should render index' do
    get notifications_url
    assert_response :success
  end

  test 'should update notification' do
    patch notification_url(@notification, format: :json), params: { notification: { read: true } }
    assert_response :success
  end

  test 'should destroy notification' do
    assert_difference('Notification.count', -1) do
      delete notification_url(@notification, format: :json)
    end
    assert_response :success
  end
end
