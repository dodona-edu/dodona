require 'test_helper'

class ActivityReadStatesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:zeus)
    sign_in @user
  end

  test 'should not mark content_page as read twice' do
    cp = create :content_page
    create :activity_read_state, activity: cp, user: @user
    post activity_activity_read_states_url(cp, format: :js), params: { activity_read_state: { activity_id: cp.id } }
    assert_response :unprocessable_entity
  end

  test 'should mark content_page as read outside course' do
    cp = create :content_page
    post activity_activity_read_states_url(cp, format: :js), params: { activity_read_state: { activity_id: cp.id } }
    assert_response :success

    assert ActivityReadState.where(user: @user, activity: cp, course: nil).any?
  end

  test 'should mark content_page as read within course' do
    course = create :course, series_count: 1, content_pages_per_series: 1, subscribed_members: [@user]
    cp = course.series.first.content_pages.first
    post activity_activity_read_states_url(cp, format: :js), params: { activity_read_state: { activity_id: cp.id, course_id: course.id } }
    assert_response :success

    assert ActivityReadState.where(user: @user, activity: cp, course: course).any?
  end

  test 'should mark content_page as read as json' do
    cp = create :content_page
    post activity_activity_read_states_url(cp, format: :json), params: { activity_read_state: { activity_id: cp.id } }
    assert_response :success

    assert ActivityReadState.where(user: @user, activity: cp, course: nil).any?
  end
end
