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

  test 'should get series by token' do
    course = create(:series, :hidden)
    get token_show_series_path(course, course.access_token)
    assert_response :success
  end

  test 'should not get series with wrong token' do
    course = create(:series, :hidden)
    get token_show_series_path(course, 'hunter2')
    assert_redirected_to :root
  end

  test 'should generate indianio_token' do
    token_pre = @instance.indianio_token
    post update_token_series_path(@instance, type: :indianio_token), params: { format: :js }
    token_mid = @instance.reload.indianio_token
    assert_not_equal token_pre, token_mid, 'token did not change'

    post update_token_series_path(@instance, type: :indianio_token), params: { format: :js }
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
