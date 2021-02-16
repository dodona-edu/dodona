require 'test_helper'

class RubricsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @evaluation = create :evaluation, :with_submissions
    @staff_member = create :staff
    @evaluation.series.course.administrating_members << @staff_member
    sign_in @staff_member
  end

  test 'should copy rubrics if course administrator' do
    from = @evaluation.evaluation_exercises.first
    create :rubric, evaluation_exercise: from
    create :rubric, evaluation_exercise: from

    [
      [@staff_member, :success],
      [create(:student), :forbidden],
      [create(:staff), :forbidden],
      [create(:zeus), :success],
      [nil, :unauthorized]
    ].each do |user, expected|
      to = create :evaluation_exercise, evaluation: @evaluation
      sign_in user if user.present?
      post copy_evaluation_rubrics_path(@evaluation, format: :js), params: {
        copy: {
          from: from.id,
          to: to.id
        }
      }
      assert_response expected
      assert_equal 2, to.rubrics.count if expected == :success

      sign_out user if user.present?
    end
  end

  test 'should add rubrics to all if course administrator' do
    [
      [@staff_member, :ok],
      [create(:student), :no],
      [create(:staff), :no],
      [create(:zeus), :ok],
      [nil, :no]
    ].each do |user, expected|
      sign_in user if user.present?
      post add_all_evaluation_rubrics_path(@evaluation), params: {
        rubric: {
          name: 'Test',
          description: 'Test',
          maximum: '20.0'
        }
      }
      assert_response :redirect
      @evaluation.evaluation_exercises.reload
      @evaluation.evaluation_exercises.each do |e|
        if expected == :ok
          assert_equal 1, e.rubrics.length
          e.update!(rubrics: [])
        end
        assert_empty e.rubrics
      end
      sign_out user if user.present?
    end
  end

  test 'should update rubric if course administrator' do
    exercise = @evaluation.evaluation_exercises.first
    rubric = create :rubric, evaluation_exercise: exercise,
                             description: 'Before test',
                             maximum: '10.0'

    [
      [@staff_member, :success],
      [create(:student), :forbidden],
      [create(:staff), :forbidden],
      [create(:zeus), :success],
      [nil, :unauthorized]
    ].each do |user, expected|
      sign_in user if user.present?
      patch evaluation_rubric_path(@evaluation, rubric, format: :json), params: {
        rubric: {
          description: 'After test',
          maximum: '20.0'
        }
      }
      assert_response expected
      sign_out user if user.present?
    end
  end

  test 'should create rubric if course administrator' do
    [
      [@staff_member, :created],
      [create(:student), :forbidden],
      [create(:staff), :forbidden],
      [create(:zeus), :created],
      [nil, :unauthorized]
    ].each do |user, expected|
      sign_in user if user.present?
      post evaluation_rubrics_path(@evaluation, format: :json), params: {
        rubric: {
          name: 'Code re-use',
          description: 'After test',
          maximum: '10.0',
          evaluation_exercise_id: @evaluation.evaluation_exercises.first.id
        }
      }
      assert_response expected
      sign_out user if user.present?
    end
  end

  test 'should not create rubric for invalid data' do
    # Missing data
    post evaluation_rubrics_path(@evaluation, format: :json), params: {
      rubric: {
        name: 'Code re-use',
        evaluation_exercise_id: @evaluation.evaluation_exercises.first.id
      }
    }
    assert_response :unprocessable_entity

    # Negative maximum
    post evaluation_rubrics_path(@evaluation, format: :json), params: {
      rubric: {
        name: 'Code re-use',
        maximum: '-20.0',
        evaluation_exercise_id: @evaluation.evaluation_exercises.first.id
      }
    }
    assert_response :unprocessable_entity
  end

  test 'should delete rubric if course administrator' do
    exercise = @evaluation.evaluation_exercises.first

    assert_equal 0, exercise.rubrics.count

    [
      [@staff_member, :success],
      [create(:student), :forbidden],
      [create(:staff), :forbidden],
      [create(:zeus), :success],
      [nil, :unauthorized]
    ].each do |user, expected|
      rubric = create :rubric, evaluation_exercise: exercise,
                               description: 'Code re-use',
                               maximum: '10.0'
      assert_equal 1, exercise.rubrics.count
      sign_in user if user.present?
      delete evaluation_rubric_path(@evaluation, rubric, format: :json)
      assert_response expected
      exercise.rubrics.reload
      assert_equal 0, exercise.rubrics.count if response == :success

      sign_out user if user.present?
      exercise.update!(rubrics: [])
    end
  end

  test 'add rubric page for a feedback session is only available for course admins' do
    [
      [@staff_member, :success],
      [create(:student), :redirect],
      [create(:staff), :redirect],
      [create(:zeus), :success],
      [nil, :redirect]
    ].each do |user, expected|
      sign_in user if user.present?
      get new_evaluation_rubric_path(@evaluation)
      assert_response expected
      sign_out user if user.present?
    end
  end

  test 'rubric page for a feedback session is only available for course admins' do
    [
      [@staff_member, :success],
      [create(:student), :redirect],
      [create(:staff), :redirect],
      [create(:zeus), :success],
      [nil, :redirect]
    ].each do |user, expected|
      sign_in user if user.present?
      get evaluation_rubrics_path(@evaluation)
      assert_response expected
      sign_out user if user.present?
    end
  end
end
