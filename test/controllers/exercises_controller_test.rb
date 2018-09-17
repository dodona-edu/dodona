require 'test_helper'

class ExercisesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Exercise, attrs: %i[access name_nl name_en]

  def setup
    @instance = create(:exercise, :description_html)
    sign_in create(:zeus)
  end

  test_crud_actions only: %i[index edit update]

  test 'should show exercise' do
    get exercise_url(@instance)
    assert_redirected_to @instance
    # follow redirect caused by 'ensure_trailing_slash'
    get response.headers['Location']
    assert_response :success
  end

  test 'should rescue from exercise not found' do
    not_id = Random.rand
    begin
      loop do
        not_id = Random.rand
        Exercise.find not_id
      end
    rescue ActiveRecord::RecordNotFound
      get exercise_url(not_id)
      assert_redirected_to exercises_path
      assert_equal flash[:alert], I18n.t('exercises.show.not_found')
    end
  end

  test 'should get exercise media' do
    Exercise.any_instance.stubs(:media_path).returns(Pathname.new('public'))

    get media_exercise_url(@instance, media: 'icon.png')

    assert_response :success
    assert_equal response.content_type, 'image/png'
  end

  test 'should get public media' do
    @instance.stubs(:media_path).returns(Pathname.new('not-a-real-directory'))
    Repository.any_instance.stubs(:full_path).returns(Pathname.new(Rails.root))

    get media_exercise_url(@instance, media: 'icon.png')

    assert_response :success
    assert_equal 'image/png', response.content_type
  end

  test 'should get exercices by repository_id' do
    get exercises_url repository_id: @instance.repository.id
    assert_response :success
  end

  test 'should get available exercises for series' do
    course = create :course, usable_repositories: [@instance.repository]
    other_exercise = create :exercise
    series_exercise = create :exercise, repository: @instance.repository
    create :exercise # Other exercise that should never show up
    series = create :series, course: course, exercises: [series_exercise]
    admin = create :staff, administrating_courses: [course], repositories: [other_exercise.repository]

    sign_out :user
    sign_in admin

    get available_exercises_series_url(series, format: :json)

    assert_response :success
    result_exercises = JSON.parse response.body

    assert result_exercises.any?{ |ex| ex['id'] == @instance.id }, 'should contain exercise usable by course'
    assert result_exercises.any?{ |ex| ex['id'] == other_exercise.id }, 'should contain exercise usable by repo admin'
    assert_equal 2, result_exercises.count, 'should only contain available exercises'
  end

  test 'should get available exercises for course with labels' do
    course = create :course, usable_repositories: [@instance.repository]
    other_exercise = create :exercise
    series_exercise = create :exercise, repository: @instance.repository
    create :exercise # Other exercise that should never show up
    series = create :series, course: course, exercises: [series_exercise]
    admin = create :staff, administrating_courses: [course], repositories: [other_exercise.repository]

    label = create :label

    sign_out :user
    sign_in admin

    get available_exercises_series_url(series, labels: [label.name], format: :json)

    assert_response :success
    result_exercises = JSON.parse response.body
    assert_equal 0, result_exercises.count, 'should not contain exercises'

    label.exercises << @instance

    get available_exercises_series_url(series, labels: [label.name], format: :json)

    assert_response :success
    result_exercises = JSON.parse response.body

    assert result_exercises.any?{ |ex| ex['id'] == @instance.id }, 'should contain exercise with label'
    assert result_exercises.all?{ |ex| ex['id'] != other_exercise.id }, 'should not contain exercise without label'
  end

  test 'should not get available exercises as student' do
    course = create :course, usable_repositories: [@instance.repository]
    create :exercise # Other exercise that should never show up
    series = create :series, course: course

    student = create :student, subscribed_courses: [course]
    sign_out :user
    sign_in student

    get available_exercises_series_url(series, format: :json)

    assert_response :redirect
  end

  def assert_response_contains_exercise(exercise, msg=nil)
    assert_response :success
    result_exercises = JSON.parse response.body
    assert result_exercises.any?{ |ex| ex['id'] == exercise.id }, msg
  end

  test 'should get edit submission with show' do
    submission = create :submission
    @instance.submissions << submission

    Submission.expects(:find).with(submission.id.to_s).returns(submission)

    get exercise_url(@instance),
        params: { edit_submission: submission }
    assert_redirected_to exercise_url(@instance)
    # follow redirect cause by 'ensure_trailing_slash'
    get response.headers['Location'],
        params: { edit_submission: submission.id }
    assert_response :success
  end
end

class ExercisesPermissionControllerTest < ActionDispatch::IntegrationTest
  setup do
    # stub file access
    Exercise.any_instance.stubs(:description_localized).returns("it's something")
    @user = create :user
    sign_in @user
  end

  def show_exercise
    get exercise_path(@instance).concat('/')
  end

  test 'user should be able to see exercise' do
    @instance = create :exercise
    show_exercise
    assert_response :success
  end

  test 'user should not be able to see invalid exercise' do
    @instance = create :exercise, :nameless
    show_exercise
    assert_redirected_to root_url
  end

  test 'user should be able to see invalid exercise when he has submissions, but not when closed' do
    @instance = create :exercise, :nameless
    create :submission, exercise: @instance, user: @user
    show_exercise
    assert_response :success
  end

  test 'admin should be able to see invalid exercise' do
    sign_in create(:staff)
    @instance = create :exercise, :nameless
    show_exercise
    assert_response :success
  end

  test 'unauthenticated user should not be able to see private exercise' do
    sign_out :user
    @instance = create :exercise, access: 'private'
    show_exercise
    assert_redirected_to sign_in_url
  end

  test 'authenticated user should not be able to see private exercise' do
    @instance = create :exercise, access: 'private'
    show_exercise
    assert_redirected_to root_url

    series = create :series
    series.exercises << @instance
    get course_exercise_path(series.course, @instance).concat('/')
    assert_redirected_to root_url
  end

  test 'repository admin should always be able to see private exercises' do
    @instance = create :exercise, access: 'private'
    @instance.repository.admins << @user
    show_exercise
    assert_response :success
  end

  test 'authenticated user should be able to see private exercise when used in a subscribed course' do
    series = create :series
    @instance = create :exercise, access: 'private'
    series.exercises << @instance
    series.course.subscribed_members << @user
    @instance.repository.allowed_courses << series.course
    get course_exercise_path(series.course, @instance).concat('/')
    assert_response :success
  end

  def create_exercises_return_valid
    create :exercise, :nameless
    create :exercise, access: 'private'
    create :exercise
  end

  test 'exercise overview should not include closed, hidden or invalid exercises' do
    visible = create_exercises_return_valid

    get exercises_url, params: { format: :json }

    exercises = JSON.parse response.body
    assert_equal 1, exercises.length
    assert_equal visible.id, exercises.first['id']
  end

  test 'exercise overview should include everything for admin' do
    create_exercises_return_valid
    sign_out :user
    sign_in create(:zeus)

    get exercises_url, params: { format: :json }

    exercises = JSON.parse response.body
    assert_equal 3, exercises.length
  end
end

class ExerciseErrorMailerTest < ActionDispatch::IntegrationTest
  setup do
    @pythia = create :judge, :git_stubbed, name: 'pythia'
    @remote = local_remote('exercises/echo')
    @repository = create :repository, remote: @remote.path
    @repository.process_exercises
  end

  test 'error email' do
    @remote.update_file('echo/config.json', 'break config') { '(╯°□°)╯︵ ┻━┻' }
    @pusher = {
      email: 'derp@ugent.be',
      name: 'derp'
    }

    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      post webhook_repository_path(@repository, pusher: @pusher)
    end
    email = ActionMailer::Base.deliveries.last

    @dodona = Rails.application.config.dodona_email

    assert_not_nil email
    assert_equal [@pusher[:email]], email.to
    assert_equal [@dodona], email.from
    assert_equal [@dodona], email.cc
  end
end
