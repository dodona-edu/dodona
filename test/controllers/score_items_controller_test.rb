require 'test_helper'

class ScoreItemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @evaluation = create :evaluation, :with_submissions
    @staff_member = create :staff
    @evaluation.series.course.administrating_members << @staff_member
    sign_in @staff_member
  end

  test 'should copy score items if course administrator' do
    from = @evaluation.evaluation_exercises.first
    create :score_item, evaluation_exercise: from
    create :score_item, evaluation_exercise: from

    [
      [@staff_member, :success],
      [create(:student), :forbidden],
      [create(:staff), :forbidden],
      [create(:zeus), :success],
      [nil, :unauthorized]
    ].each do |user, expected|
      to = create :evaluation_exercise, evaluation: @evaluation
      sign_in user if user.present?
      post copy_evaluation_score_items_path(@evaluation, format: :js), params: {
        copy: {
          from: from.id,
          to: to.id
        }
      }
      assert_response expected
      assert_equal 2, to.score_items.count if expected == :success

      sign_out user if user.present?
    end
  end

  test 'should add score items to all if course administrator' do
    [
      [@staff_member, :ok],
      [create(:student), :no],
      [create(:staff), :no],
      [create(:zeus), :ok],
      [nil, :no]
    ].each do |user, expected|
      sign_in user if user.present?
      post add_all_evaluation_score_items_path(@evaluation), params: {
        score_item: {
          name: 'Test',
          description: 'Test',
          maximum: '20.0'
        }
      }
      assert_response :redirect
      @evaluation.evaluation_exercises.reload
      @evaluation.evaluation_exercises.each do |e|
        if expected == :ok
          assert_equal 1, e.score_items.length
          e.update!(score_items: [])
        end
        assert_empty e.score_items
      end
      sign_out user if user.present?
    end
  end

  test 'should update score item if course administrator' do
    exercise = @evaluation.evaluation_exercises.first
    score_item = create :score_item, evaluation_exercise: exercise,
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
      patch evaluation_score_item_path(@evaluation, score_item, format: :json), params: {
        score_item: {
          description: 'After test',
          maximum: '20.0'
        }
      }
      assert_response expected
      sign_out user if user.present?
    end
  end

  test 'should create score item if course administrator' do
    [
      [@staff_member, :created],
      [create(:student), :forbidden],
      [create(:staff), :forbidden],
      [create(:zeus), :created],
      [nil, :unauthorized]
    ].each do |user, expected|
      sign_in user if user.present?
      post evaluation_score_items_path(@evaluation, format: :json), params: {
        score_item: {
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

  test 'should not create score item for invalid data' do
    # Missing data
    post evaluation_score_items_path(@evaluation, format: :json), params: {
      score_item: {
        name: 'Code re-use',
        evaluation_exercise_id: @evaluation.evaluation_exercises.first.id
      }
    }
    assert_response :unprocessable_entity

    # Negative maximum
    post evaluation_score_items_path(@evaluation, format: :json), params: {
      score_item: {
        name: 'Code re-use',
        maximum: '-20.0',
        evaluation_exercise_id: @evaluation.evaluation_exercises.first.id
      }
    }
    assert_response :unprocessable_entity
  end

  test 'should not update score item for invalid data' do
    score_item = create :score_item, evaluation_exercise: @evaluation.evaluation_exercises.sample
    # Negative maximum
    patch evaluation_score_item_path(@evaluation, score_item, format: :json), params: {
      score_item: {
        maximum: '-20.0'
      }
    }
    assert_response :unprocessable_entity
  end

  test 'should delete score item if course administrator' do
    exercise = @evaluation.evaluation_exercises.first

    assert_equal 0, exercise.score_items.count

    [
      [@staff_member, :success],
      [create(:student), :forbidden],
      [create(:staff), :forbidden],
      [create(:zeus), :success],
      [nil, :unauthorized]
    ].each do |user, expected|
      score_item = create :score_item, evaluation_exercise: exercise,
                                       description: 'Code re-use',
                                       maximum: '10.0'
      assert_equal 1, exercise.score_items.count
      sign_in user if user.present?
      delete evaluation_score_item_path(@evaluation, score_item, format: :json)
      assert_response expected
      exercise.score_items.reload
      assert_equal 0, exercise.score_items.count if response == :success

      sign_out user if user.present?
      exercise.update!(score_items: [])
    end
  end

  test 'add score item page for a feedback session is only available for course admins' do
    [
      [@staff_member, :success],
      [create(:student), :redirect],
      [create(:staff), :redirect],
      [create(:zeus), :success],
      [nil, :redirect]
    ].each do |user, expected|
      sign_in user if user.present?
      get new_evaluation_score_item_path(@evaluation)
      assert_response expected
      sign_out user if user.present?
    end
  end

  test 'score item page for a feedback session is only available for course admins' do
    [
      [@staff_member, :success],
      [create(:student), :redirect],
      [create(:staff), :redirect],
      [create(:zeus), :success],
      [nil, :redirect]
    ].each do |user, expected|
      sign_in user if user.present?
      get evaluation_score_items_path(@evaluation)
      assert_response expected
      sign_out user if user.present?
    end
  end
end
