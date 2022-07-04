require 'test_helper'

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  def setup
    @instance = exercises(:python_exercise)
    @user = users(:zeus)
    sign_in @user
  end

  test 'should show activity' do
    get activity_url(@instance)
    assert_response :success
  end

  test 'should show activity if removed' do
    @instance.update(status: :removed, path: nil)
    get activity_url(@instance)
    assert_response :success
  end

  test 'should show activity description' do
    get description_activity_url(@instance, token: @instance.access_token)
    assert_response :success
  end

  test 'should show content_page' do
    cp = create :content_page
    get activity_url(cp)
    assert_response :success
  end

  test 'should not show activity description with incorrect token' do
    get description_activity_url(@instance, token: 'blargh')
    assert_response :forbidden
  end

  test 'should show activity info' do
    stub_all_activities!
    # Attach exercise to courses to test sorting
    create_list(:course, 2).each { |s| s.series << create(:series, exercises: [@instance]) }
    get info_activity_url(@instance)
    assert_response :success
  end

  test 'should show activity info when programming language is nil' do
    stub_all_activities!
    @instance.update(programming_language: nil)
    get info_activity_url(@instance)
    assert_response :success
  end

  test 'should show activity info when config is invalid' do
    stub_all_activities!
    Exercise.any_instance.stubs(:merged_config).raises(StandardError.new('ALL CAPS'))
    @instance.update(status: :not_valid)
    get info_activity_url(@instance)
    assert_response :success
  end

  test 'should rescue from exercise not found' do
    not_id = Random.rand(10_000)
    begin
      loop do
        not_id = Random.rand(10_000)
        Activity.find not_id
      end
    rescue ActiveRecord::RecordNotFound
      get activity_url(not_id)
      assert_redirected_to activities_path
      assert_equal flash[:alert], I18n.t('activities.show.not_found')
    end
  end

  test 'should get activities media' do
    Exercise.any_instance.stubs(:media_path).returns(Pathname.new('public'))

    get media_activity_url(@instance, 'icon.png')

    assert_response :success
    assert_equal response.content_type, 'image/png'
    assert_equal 'bytes', response.headers['accept-ranges']
  end

  test 'should get byte-range of activities media' do
    Exercise.any_instance.stubs(:media_path).returns(Pathname.new('public'))

    get media_activity_url(@instance, 'icon.png'), headers: { range: 'bytes=150-500' }

    assert_response :success
    assert_equal response.content_type, 'image/png'
    assert_equal 351, response.content_length
    assert_equal 'bytes', response.headers['accept-ranges']
  end

  test 'should get public media' do
    @instance.stubs(:media_path).returns(Pathname.new('not-a-real-directory'))
    Repository.any_instance.stubs(:full_path).returns(Pathname.new('test/remotes/exercises/echo'))

    get media_activity_url(@instance, 'code.png')

    assert_response :success
    assert_equal 'image/png', response.content_type
    assert_equal 'bytes', response.headers['accept-ranges']
  end

  test 'should get byte-ranges of public media' do
    @instance.stubs(:media_path).returns(Pathname.new('not-a-real-directory'))
    Repository.any_instance.stubs(:full_path).returns(Pathname.new('test/remotes/exercises/echo'))

    get media_activity_url(@instance, 'code.png'), headers: { range: 'bytes=150-500' }

    assert_response :success
    assert_equal 'image/png', response.content_type
    assert_equal 351, response.content_length
    assert_equal 'bytes', response.headers['accept-ranges']
  end

  test 'exercises media should redirect to activities media' do
    Exercise.any_instance.stubs(:media_path).returns(Pathname.new('public'))
    get media_exercise_url(@instance, 'icon.png')

    assert_response :success
    assert_equal response.content_type, 'image/png'
  end

  test 'should not get private media' do
    sign_out :user
    Exercise.any_instance.stubs(:media_path).returns(Pathname.new('public'))
    @instance.update access: :private

    get media_activity_url(@instance, 'icon.png')

    assert_response :redirect
  end

  test 'should get media with token on sandbox_host' do
    @instance = create(:exercise, :description_html)
    sign_out :user
    Exercise.any_instance.stubs(:media_path).returns(Pathname.new('public'))
    @instance.update access: :private

    get description_media_activity_url(@instance, host: 'sandbox.example.com', media: 'icon.png', token: @instance.access_token)

    assert_response :success
  end

  test 'should not get media with wrong token on sandbox_host' do
    Exercise.any_instance.stubs(:media_path).returns(Pathname.new('public'))

    get description_media_activity_url(@instance, host: 'sandbox.example.com', media: 'icon.png', token: 'blargh')

    assert_response :forbidden
  end

  test 'should get activities by repository_id' do
    get activities_url repository_id: @instance.repository.id
    assert_response :success
  end

  test 'should get activities by type' do
    start_exercises = Activity.exercises.count
    start_content = Activity.content_pages.count
    get activities_url(format: :json, type: ContentPage.name)
    assert_equal start_content, JSON.parse(response.body).count
    get activities_url(format: :json, type: Exercise.name)
    assert_equal start_exercises, JSON.parse(response.body).count
  end

  test 'should get activities with certain description languages available' do
    @instance = create(:exercise, :description_html)
    # @instance has a Dutch and Englisch description
    get activities_url(format: :json, description_languages: ['en'])
    assert_equal 1, JSON.parse(response.body).count
    assert_equal @instance.id, JSON.parse(response.body)[0]['id']

    get activities_url(format: :json, description_languages: ['nl'])
    assert_equal 1, JSON.parse(response.body).count
    assert_equal @instance.id, JSON.parse(response.body)[0]['id']

    get activities_url(format: :json, description_languages: %w[en nl])
    assert_equal 1, JSON.parse(response.body).count
    assert_equal @instance.id, JSON.parse(response.body)[0]['id']

    # create exercises to obtain all possible condition combinations
    create :exercise, description_en_present: true
    create :exercise, description_nl_present: true
    create :exercise, description_nl_present: true, description_en_present: true

    get activities_url(format: :json, description_languages: ['nl'])
    assert_equal 3, JSON.parse(response.body).count
    get activities_url(format: :json, description_languages: ['en'])
    assert_equal 3, JSON.parse(response.body).count
    get activities_url(format: :json, description_languages: [])
    assert_equal Exercise.count, JSON.parse(response.body).count # should yield all exercises
  end

  test 'should get activities filtered by judge' do
    judge = @instance.judge
    get activities_url(format: :json, judge_id: judge.id)
    assert_equal Activity.where(judge: judge).count, JSON.parse(response.body).count
    assert_equal @instance.id, JSON.parse(response.body)[0]['id']

    get activities_url(format: :json, judge_id: Judge.all.last.id + 1)
    assert_equal 0, JSON.parse(response.body).count
  end

  test 'should get available activities for series' do
    start_exercises = Activity.exercises.count
    course = create :course, usable_repositories: [@instance.repository]
    other_exercise = create :exercise
    series_exercise = create :exercise, repository: @instance.repository
    create :exercise, :generated_repo # Other exercise that should never show up
    series = create :series, course: course, exercises: [series_exercise]
    admin = create :staff, administrating_courses: [course], repositories: [other_exercise.repository]

    sign_out :user
    sign_in admin

    get available_activities_series_url(series, format: :json)

    assert_response :success
    result_exercises = JSON.parse response.body

    assert result_exercises.any? { |ex| ex['id'] == @instance.id }, 'should contain exercise usable by course'
    assert result_exercises.any? { |ex| ex['id'] == other_exercise.id }, 'should contain exercise usable by repo admin'
    assert result_exercises.any? { |ex| ex['id'] == series_exercise.id }, 'should also contain exercises already used by series'
    assert_equal start_exercises + 2, result_exercises.count, 'should only contain available exercises'
  end

  test 'should get available activities for course with labels' do
    course = create :course, usable_repositories: [@instance.repository]
    other_exercise = create :exercise
    series_exercise = create :exercise, repository: @instance.repository
    create :exercise # Other exercise that should never show up
    series = create :series, course: course, exercises: [series_exercise]
    admin = create :staff, administrating_courses: [course], repositories: [other_exercise.repository]

    label = create :label

    sign_out :user
    sign_in admin

    get available_activities_series_url(series, labels: [label.name], format: :json)

    assert_response :success
    result_exercises = JSON.parse response.body
    assert_equal 0, result_exercises.count, 'should not contain exercises'

    label.activities << @instance

    get available_activities_series_url(series, labels: [label.name], format: :json)

    assert_response :success
    result_exercises = JSON.parse response.body

    assert result_exercises.any? { |ex| ex['id'] == @instance.id }, 'should contain exercise with label'
    assert result_exercises.all? { |ex| ex['id'] != other_exercise.id }, 'should not contain exercise without label'
  end

  test 'should get available activities for course with programming language' do
    course = create :course, usable_repositories: [@instance.repository]
    other_exercise = create :exercise
    series_exercise = create :exercise, repository: @instance.repository
    create :exercise # Other exercise that should never show up
    series = create :series, course: course, activities: [series_exercise]
    admin = create :staff, administrating_courses: [course], repositories: [other_exercise.repository]

    programming_language = create :programming_language

    sign_out :user
    sign_in admin

    get available_activities_series_url(series, programming_language: programming_language.name, format: :json)

    assert_response :success
    result_exercises = JSON.parse response.body
    assert_equal 0, result_exercises.count, 'should not contain exercises'

    @instance.update(programming_language: programming_language)

    get available_activities_series_url(series, programming_language: programming_language.name, format: :json)

    assert_response :success
    result_exercises = JSON.parse response.body

    assert result_exercises.any? { |ex| ex['id'] == @instance.id }, 'should contain exercise with programming language'
    assert result_exercises.all? { |ex| ex['id'] != other_exercise.id }, 'should not contain exercise with other programming language'
  end

  test 'should not get available activities as student' do
    course = create :course, usable_repositories: [@instance.repository]
    create :exercise # Other exercise that should never show up
    series = create :series, course: course

    student = create :student, subscribed_courses: [course]
    sign_out :user
    sign_in student

    get available_activities_series_url(series, format: :json)

    assert_response :forbidden
  end

  def assert_response_contains_activity(activity, msg = nil)
    assert_response :success
    result_activities = JSON.parse response.body
    assert result_activities.any? { |ex| ex['id'] == activity.id }, msg
  end

  test 'should get edit submission with show' do
    submission = create :submission, exercise: @instance

    Submission.expects(:find).with(submission.id.to_s).returns(submission)

    get activity_url(@instance),
        params: { edit_submission: submission.id }
    assert_response :success
  end

  test 'should get solution with show' do
    solutions = {}
    solutions.expects(:[]).with('test').returns('content')
    Exercise.any_instance.expects(:solutions).returns(solutions)

    get activity_url(@instance),
        params: { from_solution: 'test' }
    assert_response :success
  end

  test 'should not get solution as student' do
    student = create :student
    sign_out :user
    sign_in student

    get activity_url(@instance, format: :json),
        params: { from_solution: 'test' }
    assert_response :forbidden
  end

  test 'should list all activities within series' do
    exercises = create_list :exercise, 2, repository: @instance.repository
    exercises_in_series = exercises
    series = create :series, exercises: exercises_in_series
    create :series, activities: create_list(:exercise, 2)
    series.course.usable_repositories << @instance.repository

    get series_activities_url(series, format: :json)

    assert_response :success
    exercises_response = JSON.parse response.body
    assert_equal 2, exercises_response.count

    exercise_response_ids = exercises_response.map do |ex|
      ex['id']
    end
    exercises_in_series.each do |exercise_expected|
      assert_includes exercise_response_ids, exercise_expected.id
    end
  end

  test 'should get plaintext activity media with charset=utf-8' do
    @instance = create(:exercise, :description_html)
    Exercise.any_instance.stubs(:media_path).returns(Pathname.new('public'))

    get("#{activity_url(@instance)}/media/robots.txt")

    assert_response :success
    assert_equal response.content_type, 'text/plain; charset=utf-8'
  end

  test 'should retrieve input serviceworker script' do
    @instance = create(:exercise)
    get input_service_worker_activity_path(@instance)
    assert_response :success
    assert_equal response.content_type, 'text/javascript'

    series = create :series
    series.exercises << @instance

    get course_activity_input_service_worker_path(series.course, @instance)
    assert_response :success
    assert_equal response.content_type, 'text/javascript'

    get course_series_activity_input_service_worker_path(series.course, series, @instance)
    assert_response :success
    assert_equal response.content_type, 'text/javascript'
  end
end

class ActivitiesPermissionControllerTest < ActionDispatch::IntegrationTest
  setup do
    # stub file access
    Exercise.any_instance.stubs(:description_localized).returns("it's something")
    @user = users(:student)
    sign_in @user
  end

  def show_activity
    get activity_path(@instance).concat('/')
  end

  test 'user should be able to see activity' do
    @instance = exercises(:python_exercise)
    show_activity
    assert_response :success
  end

  test 'user should not be able to see invalid activity' do
    @instance = create :exercise, :nameless
    show_activity
    assert_redirected_to root_url
  end

  test 'user should be able to see invalid activity when he has submissions, but not when closed' do
    @instance = create :exercise, :nameless
    create :submission, exercise: @instance, user: @user
    show_activity
    assert_response :success
  end

  test 'admin should be able to see invalid activity' do
    sign_in users(:staff)
    @instance = create :exercise, :nameless
    show_activity
    assert_response :success
  end

  test 'unauthenticated user should not be able to see private activity' do
    sign_out :user
    @instance = create :exercise, access: 'private'
    show_activity
    assert_redirected_to sign_in_url
  end

  test 'unauthenticated user should be able to see public activity' do
    sign_out :user
    @instance = exercises(:python_exercise)
    show_activity
    assert_response :success
  end

  test 'authenticated user should not be able to see private activity within series' do
    @instance = create :exercise, access: 'private'
    show_activity
    assert_redirected_to root_url

    series = create :series
    series.exercises << @instance
    get course_activity_path(series.course, @instance).concat('/')
    assert_redirected_to root_url
  end

  test 'repository admin should always be able to see private activities' do
    @instance = create :exercise, access: 'private'
    @instance.repository.admins << @user
    show_activity
    assert_response :success
  end

  test 'zeus should be able to see private activities in courses' do
    instance = create :exercise, access: 'private'
    course = create :course, visibility: :hidden, registration: :closed
    sign_in users(:zeus)
    (create :series, course: course).exercises << instance
    get course_activity_path(course, instance)
    assert_response :success
  end

  test 'authenticated user should be able to see private activity when used in a subscribed course' do
    series = create :series
    @instance = create :exercise, access: 'private'
    series.exercises << @instance
    series.course.subscribed_members << @user
    @instance.repository.allowed_courses << series.course
    get course_activity_path(series.course, @instance).concat('/')
    assert_response :success
  end

  test 'authenticated user should not be able to see private activity when used in a closed series of a subscribed course' do
    series = create :series, visibility: :closed
    @instance = create :exercise, access: :private
    series.exercises << @instance
    series.course.subscribed_members << @user
    @instance.repository.allowed_courses << series.course
    get course_activity_path(series.course, @instance).concat('/')
    assert_redirected_to root_url
  end

  test 'should get activity media because record is ok' do
    @instance = exercises(:python_exercise)
    Exercise.any_instance.stubs(:media_path).returns(Pathname.new('public'))

    get("#{activity_url(@instance)}/media/icon.png")

    assert_response :success
    assert_equal response.content_type, 'image/png'
  end

  test 'should get activity media because user has submissions' do
    @instance = exercises(:python_exercise)
    Exercise.any_instance.stubs(:ok?).returns(false)
    create :submission, exercise: @instance, user: @user
    Exercise.any_instance.stubs(:media_path).returns(Pathname.new('public'))

    get("#{activity_url(@instance)}/media/icon.png")

    assert_response :success
    assert_equal response.content_type, 'image/png'
  end

  test 'should get media of private activity in course' do
    @instance = create(:exercise, :description_html, access: 'private')
    series = create :series, visibility: :hidden
    series.exercises << @instance
    series.course.enrolled_members << @user
    @instance.repository.allowed_courses << series.course
    Exercise.any_instance.stubs(:media_path).returns(Pathname.new('public'))

    get course_series_activity_url(series.course, series, @instance)
    assert_response :success, 'should have access to activity'

    get("#{course_series_activity_url(series.course, series, @instance)}media/icon.png")

    assert_response :success, 'should have access to activity media'
    assert_equal response.content_type, 'image/png'
  end

  test 'should get redirected from activity media to root_url because user has no submissions and activity is not ok' do
    @instance = exercises(:python_exercise)
    Exercise.any_instance.stubs(:ok?).returns(false)
    Exercise.any_instance.stubs(:media_path).returns(Pathname.new('public'))

    get("#{activity_url(@instance)}media/icon.png")

    assert_redirected_to root_url
  end

  test 'should get redirected from exercise media to sign_in_url because user is not signed in' do
    @instance = exercises(:python_exercise)
    Exercise.any_instance.stubs(:ok?).returns(false)
    Exercise.any_instance.stubs(:media_path).returns(Pathname.new('public'))
    sign_out @user
    get("#{activity_url(@instance)}media/icon.png")

    assert_redirected_to sign_in_url
  end

  test 'should not have access to activity media when user has no access to private activity' do
    @instance = create(:exercise, :description_html, access: :private)
    Exercise.any_instance.stubs(:media_path).returns(Pathname.new('public'))
    get("#{activity_url(@instance)}media/icon.png")

    assert_redirected_to root_url
  end

  test 'should access public activity media on default host with token' do
    sign_out :user
    @instance = exercises(:python_exercise)
    Exercise.any_instance.stubs(:media_path).returns(Pathname.new('public'))
    get(activity_url(@instance) + "media/icon.png?token=#{@instance.access_token}")

    assert_response :success
  end

  test 'should access private exercise media on default host with token' do
    sign_out :user
    @instance = create(:exercise, :description_html, access: :private)
    Exercise.any_instance.stubs(:media_path).returns(Pathname.new('public'))
    get(activity_url(@instance) + "media/icon.png?token=#{@instance.access_token}")

    assert_response :success
  end

  def create_exercises_return_valid
    create :exercise, :nameless
    create :exercise, access: 'private'
    create :exercise
  end

  test 'exercise overview should not include closed, hidden or invalid exercises' do
    start_activities = Activity.count
    visible = create_exercises_return_valid

    get activities_url, params: { format: :json }

    exercises = JSON.parse response.body
    assert_equal start_activities + 1, exercises.length
    assert_equal visible.id, exercises.first['id']
  end

  test 'exercise overview should include everything for admin' do
    start = Exercise.count
    create_exercises_return_valid
    sign_out :user
    sign_in users(:zeus)

    get activities_url, params: { format: :json }

    exercises = JSON.parse response.body
    assert_equal 3, exercises.length - start
  end

  test 'exercise solved in other course should not take into account solutions from different course' do
    ex = create_exercises_return_valid
    s1 = create :series, :generated_course
    s1.exercises << ex
    s2 = create :series, :generated_course
    s2.exercises << ex
    s1.course.enrolled_members << @user
    s2.course.enrolled_members << @user
    create :correct_submission, user: @user, course: s1.course, exercise: ex
    get activity_url(ex, format: :json)
    resp = JSON.parse response.body
    assert resp['last_solution_is_best']
    assert resp['has_solution']
    assert resp['has_correct_solution']
    get course_series_activity_url(s1.course, s1, ex, format: :json)
    resp = JSON.parse response.body
    assert resp['last_solution_is_best']
    assert resp['has_solution']
    assert resp['has_correct_solution']
    get course_series_activity_url(s2.course, s2, ex, format: :json)
    resp = JSON.parse response.body
    assert resp['last_solution_is_best']
    assert_not resp['has_solution']
    assert_not resp['has_correct_solution']
  end

  test 'reading activity read in other course should not take into account read state from different course' do
    ra = create :content_page
    s1 = create :series, :generated_course
    s1.content_pages << ra
    s2 = create :series, :generated_course
    s2.content_pages << ra
    s1.course.enrolled_members << @user
    s2.course.enrolled_members << @user
    create :activity_read_state, activity: ra, user: @user, course: s1.course
    get activity_url(ra, format: :json)
    resp = JSON.parse response.body
    assert resp['has_read']
    get course_series_activity_url(s1.course, s1, ra, format: :json)
    resp = JSON.parse response.body
    assert resp['has_read']
    get course_series_activity_url(s2.course, s2, ra, format: :json)
    resp = JSON.parse response.body
    assert_not resp['has_read']
  end
end

class ExerciseErrorMailerTest < ActionDispatch::IntegrationTest
  setup do
    @pythia = create :judge, :git_stubbed, name: 'pythia'
    @remote = local_remote('exercises/echo')
    @repository = create :repository, remote: @remote.path
    @repository.process_activities
  end

  test 'error email' do
    @remote.update_file('echo/config.json', 'break config') { '(╯°□°)╯︵ ┻━┻' }
    @pusher = {
      email: 'derp@ugent.be',
      name: 'derp'
    }

    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      post webhook_repository_path(@repository, pusher: @pusher), headers: { 'X-GitHub-Event': 'push' }
    end
    email = ActionMailer::Base.deliveries.last

    @dodona = Rails.application.config.dodona_email

    assert_not_nil email
    assert_equal [@pusher[:email]], email.to
    assert_equal [@dodona], email.from
    assert_equal [@dodona], email.cc
  end
end

class ExerciseDescriptionTest < ActionDispatch::IntegrationTest
  setup do
    desciption_md = <<-DESC
      <script>alert('What is your favorite colour?')</script>
      ## Solve this question
      What is the airspeed of an unladen swallow?
    DESC

    @exercise = exercises(:python_exercise)
    Exercise.any_instance.stubs(:description_localized).returns(desciption_md)
    Exercise.any_instance.stubs(:update_config)
    stub_status(Exercise.any_instance, 'ok')
  end

  test 'iframe to exercise description should be present in the page' do
    sign_in users(:student)
    get activity_url(@exercise).concat('/')

    assert_includes response.body, description_activity_url(@exercise, token: @exercise.access_token)
  end

  test 'iframe should set dark mode to false when there is no logged in user' do
    get activity_url(@exercise).concat('/')

    assert_includes response.body, description_activity_url(@exercise, token: @exercise.access_token, dark: false)
  end

  test 'script in exercise description should not be present in the page' do
    get activity_url(@exercise).concat('/')

    assert_not_includes response.body, 'What is your favorite colour?'
  end

  test 'exercise page within series should contain extra navigation' do
    course = courses(:course1)
    exercise = exercises(:python_exercise)
    other_exercise = create :exercise
    series = create :series, course: course, exercises: [exercise, other_exercise]

    get course_series_activity_url(course, series, exercise)

    assert_response :success
    assert_includes response.body, 'activity-sidebar'
  end

  test 'exercise page without series should not contain extra navigation' do
    course = courses(:course1)
    exercise = exercises(:python_exercise)
    other_exercise = create :exercise
    create :series, course: course, exercises: [exercise, other_exercise]

    get activity_url(exercise)

    assert_response :success
    assert_not_includes response.body, 'activity-sidebar'
  end

  test 'json representation of exercise should contain the sandbox and access token in its description url' do
    exercise = exercises(:python_exercise)

    get activity_url(exercise), params: { format: :json }

    assert_response :success

    exercise_json = JSON.parse response.body
    description_url = exercise_json['description_url']

    assert description_url.include?(Rails.configuration.sandbox_host)
    assert description_url.include?(exercise.access_token)
  end
end
