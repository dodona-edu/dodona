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
    get exercise_url(@instance).concat('/')
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

    # Help
    get exercise_url(@instance).concat("/?edit_submission=#{submission.id}")
    assert_response :success
  end
end
