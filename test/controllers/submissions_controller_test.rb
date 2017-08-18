require 'test_helper'

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Submission, attrs: %i[code exercise_id]

  setup do
    @instance = create :submission
    sign_in create(:zeus)
  end

  test_crud_actions only: %i[index show create], except: %i[create_redirect]

  test 'should add submissions to delayed_job queue' do
    assert_jobs_enqueued(1) do
      create_request
    end
  end

  test 'create submission should respond with ok' do
    create_request_expect
    assert_response :success
  end

  test 'create submission within course' do
    attrs = generate_attr_hash
    course = create :course
    attrs[:course_id] = course.id

    submission = create_request_expect attr_hash: attrs

    assert_not_nil submission.course, 'Course was not properly set'
    assert_equal course, submission.course
  end

  test 'should get submission edit page' do
    get edit_submission_path(@instance)
    assert_redirected_to exercise_url(
                           @instance.exercise,
                           anchor: 'submission-card',
                           edit_submission: @instance
                         )
  end

  test 'should download submission code' do
    get download_submission_path(@instance)
    assert_response :success
  end

  test 'should evaluate submission' do
    assert_difference('Delayed::Job.count', +1) do
      get evaluate_submission_path(@instance)
      assert_redirected_to @instance
    end
  end

  test 'submission media should redirect to exercise media' do
    get media_submission_path(@instance, 'dank_meme.jpg')
    assert_redirected_to media_exercise_path(@instance.exercise, 'dank_meme.jpg')
  end

  def rejudge_submissions(**params)
    post mass_rejudge_submissions_path, params: params
    assert_response :success
  end

  test 'should rejudge all submissions' do
    create(:series, :with_submissions)
    assert_jobs_enqueued(Submission.count) do
      rejudge_submissions
    end
  end

  test 'should rejudge user submissions' do
    series = create(:series, :with_submissions)
    user = User.in_course(series.course).sample
    assert_jobs_enqueued(user.submissions.count) do
      rejudge_submissions user_id: user.id
    end
  end

  test 'should rejudge course submissions' do
    series = create(:series, :with_submissions)
    assert_jobs_enqueued(Submission.in_course(series.course).count) do
      rejudge_submissions course_id: series.course.id
    end
  end

  test 'should rejudge series submissions' do
    series = create(:series, :with_submissions)
    assert_jobs_enqueued(Submission.in_series(series).count) do
      rejudge_submissions series_id: series.id
    end
  end

  test 'should rejudge exercise submissions' do
    series = create(:series, :with_submissions)
    exercise = series.exercises.sample
    assert_jobs_enqueued(exercise.submissions.count) do
      rejudge_submissions exercise_id: exercise.id
    end
  end
end
