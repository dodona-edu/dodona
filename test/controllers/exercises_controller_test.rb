require 'test_helper'

class ExercisesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Exercise, attrs: %i[visibility name_nl name_en]

  def setup
    @instance = create(:exercise)
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

  test 'should get exercices by repository_id' do
    get exercises_url repository_id: @instance.repository.id
    assert_response :success
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

  test 'user should not be able to see closed exercise' do
    @instance = create :exercise, visibility: 'closed'
    show_exercise
    assert_redirected_to root_url
  end

  test 'user should not be able to see invalid exercise' do
    @instance = create :exercise, :nameless
    show_exercise
    assert_redirected_to root_url
  end

  test 'user should be able to see invalid exercise when he has submissions' do
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
end
