require 'test_helper'

class SeriesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Series, attrs: %i[name description course_id visibility order deadline]

  setup do
    @instance = create(:series)
    sign_in users(:zeus)
  end

  test_crud_actions except: %i[new index create_redirect update_redirect destroy_redirect]

  test 'should show course with exercise with nil programming language' do
    exercise = create :exercise, programming_language: nil
    @instance.exercises << exercise
    get series_url(@instance)
    assert_response :success
  end

  test 'should get new for course' do
    course = courses(:course1)
    get new_course_series_url(course)
    assert_response :success
  end

  test 'create series should redirect to edit' do
    instance = create_request_expect
    assert_redirected_to edit_series_url(instance)
  end

  test 'should not create series or get new when not course admin' do
    sign_out :user
    sign_in users(:staff)
    course = courses(:course1)

    get new_course_series_url(course)
    assert_response :redirect

    create_request
    assert_response :redirect
  end

  test 'course admin should be able to update course' do
    sign_out :user
    @admin = users(:student)
    sign_in @admin

    @instance.course.administrating_members << @admin
    patch series_url(@instance, series: { name: 'Dirichlet' })

    assert_response :redirect
    assert_equal 'Dirichlet', @instance.reload.name
  end

  test 'new series for non-existent course should 404' do
    assert_raises ActiveRecord::RecordNotFound do
      get new_course_series_url(Course.reorder(id: :desc).first.id + 1)
    end
  end

  test 'create series with missing course_id should 422' do
    post series_index_url, params: { series: { name: 'Test series' }, format: :json }
    assert_response :unprocessable_entity
  end

  test 'update series should redirect to course' do
    instance = update_request_expect(attr_hash: { series: { description: 'new description' } })
    assert_redirected_to course_url(instance.course, series: instance, anchor: instance.anchor)
  end

  test 'destroy series should redirect to course' do
    course = @instance.course
    destroy_request
    assert_redirected_to course_url(course)
  end

  test 'should generate scoresheet' do
    series = create(:series, :with_submissions)
    get scoresheet_series_path(series)
    assert_response :success
  end

  test 'should mass rejudge' do
    series = create(:series, :with_submissions)
    assert_jobs_enqueued(Submission.in_series(series).count) do
      post mass_rejudge_series_path(series), params: { format: 'application/javascript' }
      assert_response :success
    end
  end

  test 'should add activities to series' do
    stub_all_activities!
    activity = exercises(:python_exercise)
    post add_activity_series_path(@instance),
         params: {
           format: 'application/javascript',
           activity_id: activity.id
         }
    assert_response :success
    assert @instance.reload.activities.include? activity
  end

  test 'should remove activity from series' do
    activity = create(:exercise, series: [@instance])
    post remove_activity_series_path(@instance),
         params: {
           format: 'application/javascript',
           activity_id: activity.id
         }
    assert_response :success
    assert_not @instance.activities.include?(activity)
  end

  test 'repository admin adding private activity to series should add course to repository\'s allowed courses' do
    activity = create :exercise, access: :private
    post add_activity_series_path @instance, params: { format: 'application/javascript', activity_id: activity.id }
    assert activity.repository.allowed_courses.include? @instance.course
  end

  test 'course admin should not be able to add private activity to series' do
    activity = create :exercise, access: :private
    user = create :user
    sign_in user
    @instance.course.administrating_members << user
    post add_activity_series_path @instance, params: { format: 'application/javascript', activity_id: activity.id }
    assert_not @instance.activities.include? activity
  end

  test 'should reorder activities' do
    activities = create_list(:exercise, 10, series: [@instance])
    activities.shuffle!
    ids = activities.map(&:id)
    post reorder_activities_series_path @instance, params: { format: 'application/javascript', order: ids.to_json }
    assert_response :success
    assert_equal ids, @instance.series_memberships.map(&:activity_id)
  end

  test 'missed deadlines should have correct class' do
    series = create :series, deadline: 1.day.ago
    create :exercise, series: [series]

    get series_url(series)

    assert_response :success
    assert_match(/deadline-passed/, response.body)
  end

  test 'upcoming deadlines should have correct class' do
    series = create :series, deadline: 1.day.from_now
    create :exercise, series: [series]

    get series_url(series)
    assert_response :success
    assert_match(/deadline-future/, response.body)
  end

  test 'update should work using api' do
    # https://github.com/dodona-edu/dodona/issues/1765
    sign_out :user

    user = users(:staff)
    token = create :api_token, user: user
    @instance.course.administrating_members << user

    updated_description = 'The new description value.'

    original_csrf_protection = ActionController::Base.allow_forgery_protection
    begin
      ActionController::Base.allow_forgery_protection = true
      patch series_url(@instance, format: :json, series: { description: updated_description }),
            params: { format: :json },
            headers: { 'Authorization' => token.token }
      assert_response :success
      assert_equal updated_description, @instance.reload.description
    ensure
      ActionController::Base.allow_forgery_protection = original_csrf_protection
    end
  end

  test 'update should not work over api without token' do
    # https://github.com/dodona-edu/dodona/issues/1765
    sign_out :user

    user = users(:staff)
    @instance.course.administrating_members << user

    updated_description = 'The new description value.'

    original_csrf_protection = ActionController::Base.allow_forgery_protection
    begin
      ActionController::Base.allow_forgery_protection = true
      patch series_url(@instance, format: :json, series: { description: updated_description }),
            params: { format: :json }
      assert_response :unauthorized
      assert_not_equal updated_description, @instance.reload.description
    ensure
      ActionController::Base.allow_forgery_protection = original_csrf_protection
    end
  end
end

class SeriesVisibilityTest < ActionDispatch::IntegrationTest
  setup do
    @series = create :series, activity_count: 1, exercise_submission_count: 1
    @course = @series.course
    @student = users(:student)
    @zeus = users(:zeus)
    @course_admin = users(:staff)
    @course.administrating_members << @course_admin
  end

  def assert_show_and_overview(authorized, token: nil)
    response = authorized ? :success : :redirect
    get series_url(@series, token: token)
    assert_response response
    get overview_series_url(@series, token: token)
    assert_response response
  end

  test 'student should only see visible series in course' do
    @hidden_series = create :series, visibility: :hidden, course: @course
    @closed_series = create :series, visibility: :closed, course: @course

    sign_in @student
    get course_series_index_url(@course, format: :json)

    assert_response :success

    result_series = response.parsed_body

    assert_equal 1, result_series.count, 'expected only one (visible) series'

    assert_equal @series.id, result_series.first['id']
  end

  test 'course admin should see all series in course' do
    @hidden_series = create :series, visibility: :hidden, course: @course
    @closed_series = create :series, visibility: :closed, course: @course

    sign_in @course_admin
    get course_series_index_url(@course, format: :json)

    assert_response :success

    result_series = response.parsed_body

    assert_equal 3, result_series.count, 'expected all series (open, visible and closed)'
  end

  test 'student should see visible series' do
    sign_in @student
    assert_show_and_overview true
  end

  test 'student should not see hidden or closed series without token' do
    sign_in @student
    @series.update(visibility: :hidden)
    assert_show_and_overview false
    @series.update(visibility: :closed)
    assert_show_and_overview false
  end

  test 'student should see hidden series with token' do
    sign_in @student
    @series.update(visibility: :hidden)
    assert_show_and_overview true, token: @series.access_token
  end

  test 'student should not see hidden series with wrong token' do
    sign_in @student
    @series.update(visibility: :hidden)
    assert_show_and_overview false, token: 'hunter2'
  end

  test 'student should not see closed series with token' do
    sign_in @student
    @series.update(visibility: :closed)
    assert_show_and_overview false, token: @series.access_token
  end

  test 'not logged in should not see hidden or closed series' do
    @series.update(visibility: :hidden)
    assert_show_and_overview false
    @series.update(visibility: :closed)
    assert_show_and_overview false
  end

  test 'should get series scoresheet as course admin' do
    sign_in @course_admin
    get scoresheet_series_url(@series)
    assert_response :success, "#{@course_admin} should be able to get series scoresheet"
  end

  test 'should get series scoresheet in csv format as course admin' do
    sign_in @course_admin
    get scoresheet_series_url(@series, format: :csv)
    assert_response :success, "#{@course_admin} should be able to get series scoresheet"
  end

  test 'should get series scoresheet in json format as course admin' do
    sign_in @course_admin
    get scoresheet_series_url(@series, format: :json)
    assert_response :success, "#{@course_admin} should be able to get series scoresheet"
  end

  test 'should not get series scoresheet as normal user' do
    sign_in @student
    get scoresheet_series_url(@series)
    assert_response :redirect, "#{@student} should not be able to get series scoresheet"
  end

  test 'course admin should see hidden and closed series without token' do
    sign_in @course_admin
    @series.update(visibility: :hidden)
    assert_show_and_overview true
    @series.update(visibility: :closed)
    assert_show_and_overview true
  end

  test 'zeus should see hidden and closed series without token' do
    sign_in @zeus
    @series.update(visibility: :hidden)
    assert_show_and_overview true
    @series.update(visibility: :closed)
    assert_show_and_overview true
  end
end
