require 'test_helper'

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Submission, attrs: %i[code exercise_id]

  setup do
    stub_all_activities!
    @instance = create :correct_submission
    @zeus = create(:zeus)
    sign_in @zeus
  end

  test_crud_actions only: %i[index show create], except: %i[create_redirect]

  test 'should fetch last correct submissions for exercise' do
    users = create_list :user, 10
    c = create :course, series_count: 1, activities_per_series: 1
    e = c.series.first.exercises.first

    submissions = users.map { |u| create :correct_submission, user: u, exercise: e, course: c }
    users.each { |u| create :wrong_submission, user: u, exercise: e, course: c }

    # create a correct submission with another exercise, to check if
    # most_recent works
    create :correct_submission, user: users.first

    get course_activity_submissions_url c, e, most_recent_correct_per_user: true, format: :json

    results = JSON.parse response.body
    result_ids = results.map { |r| r['id'] }

    assert_equal submissions.count, result_ids.count
    submissions.each do |sub|
      assert_includes result_ids, sub.id
    end
  end

  test 'should be able to search by exercise name' do
    u = create :user
    sign_in u
    e1 = create :exercise, name_en: 'abcd'
    e2 = create :exercise, name_en: 'efgh'
    create :submission, exercise: e1, user: u
    create :submission, exercise: e2, user: u

    get submissions_url, params: { filter: 'abcd', format: :json }

    assert_equal 1, JSON.parse(response.body).count
  end

  test 'should be able to search by user name' do
    u1 = create :user, last_name: 'abcd'
    u2 = create :user, last_name: 'efgh'
    create :submission, user: u1
    create :submission, user: u2

    get submissions_url, params: { filter: 'abcd', format: :json }

    assert_equal 1, JSON.parse(response.body).count
  end

  test 'should be able to search by status' do
    u = create :user
    sign_in u
    create :submission, status: :correct, user: u
    create :submission, status: :wrong, user: u

    get submissions_url, params: { status: 'correct', format: :json }

    assert_equal 1, JSON.parse(response.body).count
  end

  test 'should be able to search by course label' do
    u1 = create :user
    u2 = create :user
    course = create :course
    cm = CourseMembership.create(user: u1, course: course, status: :student)
    CourseMembership.create(user: u2, course: course, status: :student)
    CourseLabel.create(name: 'test', course_memberships: [cm], course: course)
    create :submission, status: :correct, user: u1, course: course
    create :submission, status: :wrong, user: u2, course: course
    get course_submissions_url course, params: { course_labels: ['test'], format: :json }

    assert_equal 1, JSON.parse(response.body).count
  end

  test 'normal user should not be able to search by course label' do
    u1 = create :user
    u2 = create :user
    sign_in u2
    course = create :course
    cm = CourseMembership.create(user: u1, course: course, status: :student)
    CourseMembership.create(user: u2, course: course, status: :student)
    CourseLabel.create(name: 'test', course_memberships: [cm], course: course)
    create :submission, status: :correct, user: u1, course: course
    create :submission, status: :wrong, user: u2, course: course

    get course_submissions_url course, params: { course_labels: ['test'], format: :json }

    assert_equal 1, JSON.parse(response.body).count
  end

  test 'submission http caching works' do
    get submissions_path
    assert_response :ok
    assert_not_empty @response.headers['ETag']
    assert_not_empty @response.headers['Last-Modified']
    get submissions_path, headers: {
      'If-None-Match' => @response.headers['ETag'],
      'If-Modified-Since' => @response.headers['Last-Modified']
    }
    assert_response :not_modified
  end

  test 'should add submissions to delayed_job queue' do
    submission = nil
    assert_jobs_enqueued(1) do
      submission = create_request_expect
    end
    assert submission.queued?
  end

  test 'create submission should respond with ok' do
    create_request_expect
    assert_response :success
  end

  test 'should not create submission for content page' do
    attrs = generate_attr_hash
    attrs[:exercise_id] = create(:content_page).id
    create_request(attr_hash: attrs)
    assert_response :unprocessable_entity
  end

  test 'create submission should respond bad_request without an exercise' do
    attrs = generate_attr_hash
    attrs.delete(:exercise_id)
    create_request(attr_hash: attrs)
    assert_response :unprocessable_entity
  end

  test 'create submission within course' do
    attrs = generate_attr_hash
    course = create :course
    course.subscribed_members << @zeus
    course.series << create(:series)
    course.series.first.exercises << Exercise.find(attrs[:exercise_id])
    attrs[:course_id] = course.id

    submission = create_request_expect attr_hash: attrs

    assert_not_nil submission.course, 'Course was not properly set'
    assert_equal course.id, submission.course.id
  end

  test 'unregistered user submitting to private exercise in moderated course should fail' do
    attrs = generate_attr_hash
    course = create :course, moderated: true
    exercise = Exercise.find(attrs[:exercise_id])
    exercise.update(access: :private)
    course.series << create(:series)
    course.series.first.exercises << exercise
    attrs[:course_id] = course.id
    user = create :user
    sign_in user

    create_request attr_hash: attrs

    assert_response :unprocessable_entity
  end

  test 'should get submission edit page' do
    get edit_submission_path(@instance)
    assert_redirected_to activity_url(
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
    assert_redirected_to media_activity_path(@instance.exercise, 'dank_meme.jpg')
  end

  test 'submission media should redirect to exercise media and keep token' do
    get media_submission_path(@instance, 'dank_meme.jpg', token: @instance.exercise.access_token)
    assert_redirected_to media_activity_path(@instance.exercise, 'dank_meme.jpg', token: @instance.exercise.access_token)
  end

  def rejudge_submissions(**params)
    post mass_rejudge_submissions_path, params: params
    assert_response :success
  end

  test 'should enqeueue submissions delayed ' do
    create(:series, :with_submissions)

    # in test env, default and export queues are evaluated inline
    orig = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = true # delay all

    # should only enqueue a single job which will then enqueue all other jobs
    assert_jobs_enqueued(1) do
      rejudge_submissions
    end

    Delayed::Worker.delay_jobs = orig
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
    series.course.subscribed_members << @zeus
    assert_jobs_enqueued(Submission.in_course(series.course).count) do
      rejudge_submissions course_id: series.course.id
    end
  end

  test 'should rejudge series submissions' do
    series = create(:series, :with_submissions)
    series.course.subscribed_members << @zeus
    assert_jobs_enqueued(Submission.in_series(series).count) do
      rejudge_submissions series_id: series.id
    end
  end

  test 'should rejudge exercise submissions' do
    series = create :series, :with_submissions
    exercise = series.exercises.sample
    assert_jobs_enqueued(exercise.submissions.count) do
      rejudge_submissions activity_id: exercise.id
    end
  end
end
