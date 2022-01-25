require 'test_helper'

class ActivityReadStatesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers ActivityReadState, attrs: %i[activity_id]

  def setup
    @user = users(:zeus)
    sign_in @user
  end

  test_crud_actions only: %i[index]

  test 'should be able to search by activity name' do
    u = create :user
    sign_in u
    a1 = create :content_page, name_en: 'abcd'
    a2 = create :content_page, name_en: 'efgh'
    create :activity_read_state, activity: a1, user: u
    create :activity_read_state, activity: a2, user: u

    get activity_read_states_url, params: { filter: 'abcd', format: :json }

    assert_equal 1, JSON.parse(response.body).count
  end

  test 'should be able to search by user name' do
    u1 = create :user, last_name: 'abcd'
    u2 = create :user, last_name: 'efgh'
    a1 = create :content_page, name_en: 'test'
    create :activity_read_state, activity: a1, user: u1
    create :activity_read_state, activity: a1, user: u2

    get activity_read_states_url, params: { filter: 'abcd', format: :json }

    assert_equal 1, JSON.parse(response.body).count
  end

  test 'should be able to search by course label' do
    u1 = users(:student)
    u2 = users(:staff)
    course = courses(:course1)
    cm = CourseMembership.create(user: u1, course: course, status: :student)
    CourseMembership.create(user: u2, course: course, status: :student)
    CourseLabel.create(name: 'test', course_memberships: [cm], course: course)
    a1 = create :content_page, name_en: 'test'
    series = create :series, course: course
    series.exercises << a1
    create :activity_read_state,  user: u1, activity: a1, course: course
    create :activity_read_state,  user: u2, activity: a1, course: course
    get course_activity_read_states_url course, params: { course_labels: ['test'], format: :json }

    assert_equal 1, JSON.parse(response.body).count
  end

  test 'normal user should not be able to search by course label' do
    u1 = users(:student)
    u2 = users(:staff)
    sign_in u2
    course = courses(:course1)
    cm = CourseMembership.create(user: u1, course: course, status: :student)
    CourseMembership.create(user: u2, course: course, status: :student)
    CourseLabel.create(name: 'test', course_memberships: [cm], course: course)
    a1 = create :content_page, name_en: 'test'
    series = create :series, course: course
    series.exercises << a1
    create :activity_read_state,  user: u1, activity: a1, course: course
    create :activity_read_state,  user: u2, activity: a1, course: course
    get course_activity_read_states_url course, params: { course_labels: ['test'], format: :json }

    assert_equal 1, JSON.parse(response.body).count
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
