require 'test_helper'

class ScoreItemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @evaluation = create :evaluation, :with_submissions
    @staff_member = users(:staff)
    @evaluation.series.course.administrating_members << @staff_member
    sign_in @staff_member
  end

  test 'should update score item if course administrator' do
    exercise = @evaluation.evaluation_exercises.first
    score_item = create :score_item, evaluation_exercise: exercise,
                                     description: 'Before test',
                                     maximum: '10.0'

    [
      [@staff_member, :success],
      [users(:student), :forbidden],
      [create(:staff), :forbidden],
      [users(:zeus), :success],
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

  test 'should update all score items if course administrator' do
    exercise = @evaluation.evaluation_exercises.first
    score_items = create_list :score_item, 3, evaluation_exercise: exercise,
                                              description: 'Before test',
                                              maximum: '10.0'

    [
      [@staff_member, :success],
      [users(:student), :forbidden],
      [create(:staff), :forbidden],
      [users(:zeus), :success],
      [nil, :unauthorized]
    ].each do |user, expected|
      sign_in user if user.present?
      patch evaluation_evaluation_exercise_score_items_path(@evaluation, exercise, format: :json), params: {
        score_items: [
          { id: score_items[0].id, name: 'edited', description: 'After test', maximum: '20.0' },
          { name: 'new', description: 'new value', maximum: '25.0' }
        ]
      }

      assert_response expected

      exercise.score_items.reload
      if expected == :success
        assert_equal 2, exercise.score_items.count
        assert_equal 'After test', exercise.score_items.first.description
        assert_in_delta(20.0, exercise.score_items.first.maximum)
        assert_equal 'new', exercise.score_items.last.name
        assert_equal 'new value', exercise.score_items.last.description
        assert_in_delta(25.0, exercise.score_items.last.maximum)

        # reset
        exercise.score_items.each(&:destroy)
        score_items = create_list :score_item, 3, evaluation_exercise: exercise,
                                                  description: 'Before test',
                                                  maximum: '10.0'
      else
        assert_equal 3, exercise.score_items.count
      end

      sign_out user if user.present?
    end
  end

  test 'should create score item if course administrator' do
    [
      [@staff_member, :created],
      [users(:student), :forbidden],
      [create(:staff), :forbidden],
      [users(:zeus), :created],
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
      [users(:student), :forbidden],
      [create(:staff), :forbidden],
      [users(:zeus), :success],
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
end
