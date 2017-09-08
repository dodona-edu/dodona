require 'test_helper'

class SeriesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Series, attrs: %i[name description course_id visibility order deadline indianio_support]

  setup do
    @instance = create(:series)
    sign_in create(:zeus)
  end

  test_crud_actions except: %i[create_redirect update_redirect destroy_redirect]

  test 'create series should redirect to edit' do
    instance = create_request_expect
    assert_redirected_to edit_series_url(instance)
  end

  test 'course admin should be able to update course' do
    sign_out :user
    @admin = create :student
    sign_in @admin

    @instance.course.administrating_members << @admin
    patch series_url(@instance, series: { name: 'Dirichlet' })

    assert_response :redirect
    assert_equal 'Dirichlet', @instance.reload.name
  end

  test 'update series should redirect to course' do
    instance = update_request_expect
    assert_redirected_to course_url(instance.course, all: true, anchor: "series-#{instance.name.parameterize}")
  end

  test 'destroy series should redirect to course' do
    course = @instance.course
    destroy_request
    assert_redirected_to course_url(course)
  end

  test 'should download solutions' do
    series = create(:series, :with_submissions)
    get download_solutions_series_path(series)
    assert_response :success
    assert_zip response.body, with_info: false
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

  test 'should generate indianio_token' do
    token_pre = @instance.indianio_token
    post reset_token_series_path(@instance, type: :indianio_token), params: { format: :js }
    token_mid = @instance.reload.indianio_token
    assert_not_equal token_pre, token_mid, 'token did not change'

    post reset_token_series_path(@instance, type: :indianio_token), params: { format: :js }
    token_after = @instance.reload.indianio_token
    assert_not_equal token_mid, token_after, 'token did not change'
  end

  test 'enabling indianio support should generate token' do
    @instance.update(indianio_token: nil)
    patch series_url(@instance, series: { indianio_support: '1' })
    assert_not_nil @instance.reload.indianio_token
  end

  test 'disabling indianio support should delete token' do
    @instance.update(indianio_token: 'something')
    patch series_url(@instance, series: { indianio_support: '0' })
    assert_nil @instance.reload.indianio_token
  end

  test 'should add exercise to series' do
    exercise = create(:exercise)
    post add_exercise_series_path(@instance),
         params: {
           format: 'application/javascript',
           exercise_id: exercise.id
         }
    assert_response :success
    assert @instance.exercises.include? exercise
  end

  test 'should remove exercise from series' do
    exercise = create(:exercise, series: [@instance])
    post remove_exercise_series_path(@instance),
         params: {
           format: 'application/javascript',
           exercise_id: exercise.id
         }
    assert_response :success
    assert !@instance.exercises.include?(exercise)
  end

  test 'should reorder exercises' do
    exercises = create_list(:exercise, 10, series: [@instance])
    exercises.shuffle!
    ids = exercises.map(&:id)
    post reorder_exercises_series_path(@instance), params: { order: ids.to_json }
    assert_response :success
    assert_equal ids, @instance.series_memberships.map(&:exercise_id)
  end
end

class SeriesVisibilityTest < ActionDispatch::IntegrationTest
  setup do
    @series = create :series
    @student = create :student
    @zeus = create :zeus
    @course_admin = create :student
    @series.course.administrating_members << @course_admin
  end

  def assert_show_and_overview(authorized, token: nil)
    response = authorized ? :success : :redirect
    get series_url(@series, token: token)
    assert_response response
    get overview_series_url(@series, token: token)
    assert_response response
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

class SeriesIndianioDownloadControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = create :student
    @series = create :series,
                     :with_submissions,
                     indianio_token: 'supergeheimtoken',
                     exercise_submission_users: [@student]
  end

  test 'should download solutions with token and email' do
    get indianio_download_url @series.indianio_token,
                              params: {
                                email: @student.email
                              }
    assert_response :success
    assert_zip response.body,
               with_info: true,
               solution_count: @series.exercises.count
  end

  test 'should download solutions even when user does not have submissions' do
    @other_student = create :student
    get indianio_download_url @series.indianio_token,
                              params: {
                                email: @other_student.email
                              }
    assert_response :success
    assert_zip response.body,
               with_info: true,
               solution_count: @series.exercises.count
  end

  test 'should return 404 when email does not exist' do
    @other_student = create :student
    get indianio_download_url @series.indianio_token,
                              params: {
                                email: 'hupse@flup.se'
                              }
    assert_response :not_found
  end

  test 'should not download solutions with wrong token' do
    get indianio_download_url 'hupseflupse',
                              params: {
                                email: @student.email
                              }
    assert_response :unauthorized
  end
end
