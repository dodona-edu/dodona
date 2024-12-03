require 'test_helper'

class EvaluationExerciseControllerTest < ActionDispatch::IntegrationTest
  def setup
    @evaluation = create :evaluation, :with_submissions
    @staff_member = users(:staff)
    @evaluation.series.course.administrating_members << @staff_member
    @exercise = @evaluation.evaluation_exercises.first
    sign_in @staff_member
  end

  test 'can update visibility as course admin' do
    [
      [@staff_member, :success],
      [users(:student), :forbidden],
      [create(:staff), :forbidden],
      [users(:zeus), :success],
      [nil, :unauthorized]
    ].each do |user, expected|
      sign_in user if user.present?

      @exercise.update!(visible_score: true)

      assert_predicate @exercise, :visible_score?

      patch evaluation_exercise_path(@exercise, format: :js), params: {
        evaluation_exercise: {
          visible_score: false
        }
      }

      assert_response expected
      @exercise.reload
      if expected == :success
        assert_not @exercise.visible_score?
      else
        assert_predicate @exercise, :visible_score?
      end

      sign_out user if user.present?
    end
  end

  test 'should update all score items if course administrator' do
    score_items = create_list :score_item, 3, evaluation_exercise: @exercise,
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
      patch evaluation_exercise_path(@exercise, format: :json), params: {
        evaluation_exercise: {
          score_items: [
            { id: score_items[0].id, name: 'edited', description: 'After test', maximum: '20.0' },
            { name: 'new', description: 'new value', maximum: '25.0' }
          ]
        }
      }

      assert_response expected

      @exercise.score_items.reload
      if expected == :success
        assert_equal 2, @exercise.score_items.count
        assert_equal 'After test', @exercise.score_items.first.description
        assert_in_delta(20.0, @exercise.score_items.first.maximum)
        assert_equal 'new', @exercise.score_items.last.name
        assert_equal 'new value', @exercise.score_items.last.description
        assert_in_delta(25.0, @exercise.score_items.last.maximum)

        # reset
        @exercise.score_items.each(&:destroy)
        score_items = create_list :score_item, 3, evaluation_exercise: @exercise,
                                                  description: 'Before test',
                                                  maximum: '10.0'
      else
        assert_equal 3, @exercise.score_items.count
      end

      sign_out user if user.present?
    end
  end

  test 'should not create score item for invalid data' do
    # Missing data
    patch evaluation_exercise_path(@exercise, format: :json), params: {
      evaluation_exercise: {
        score_items: [
          { name: 'new' }
        ]
      }
    }

    assert_response :unprocessable_entity

    # Negative maximum
    patch evaluation_exercise_path(@exercise, format: :json), params: {
      evaluation_exercise: {
        score_items: [
          { name: 'new', description: 'new value', maximum: '-20.0' }
        ]
      }
    }

    assert_response :unprocessable_entity
  end

  test 'should not update score item for invalid data' do
    score_item = create :score_item, evaluation_exercise: @exercise

    # Negative maximum
    patch evaluation_exercise_path(@exercise, format: :json), params: {
      evaluation_exercise: {
        score_items: [
          { id: score_item.id, maximum: '-20.0' }
        ]
      }
    }

    assert_response :unprocessable_entity
  end

  test 'should delete score item if course administrator' do
    assert_equal 0, @exercise.score_items.count

    [
      [@staff_member, :success],
      [users(:student), :forbidden],
      [create(:staff), :forbidden],
      [users(:zeus), :success],
      [nil, :unauthorized]
    ].each do |user, expected|
      create :score_item, evaluation_exercise: @exercise,
                          description: 'Code re-use',
                          maximum: '10.0'

      assert_equal 1, @exercise.score_items.count
      sign_in user if user.present?
      patch evaluation_exercise_path(@exercise, format: :json), params: {
        evaluation_exercise: {
          score_items: []
        }
      }, as: :json

      assert_response expected
      @exercise.score_items.reload
      assert_equal 0, @exercise.score_items.count if response == :success

      sign_out user if user.present?
      @exercise.update!(score_items: [])
    end
  end
end
