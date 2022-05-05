require 'test_helper'

class FeedbacksControllerTest < ActionDispatch::IntegrationTest
  include EvaluationHelper

  def setup
    @evaluation = create :evaluation, :with_submissions
    exercise = @evaluation.evaluation_exercises.first
    @score_item1 = create :score_item, evaluation_exercise: exercise,
                                       description: 'First item',
                                       maximum: '10.0'
    @score_item2 = create :score_item, evaluation_exercise: exercise,
                                       description: 'Second item',
                                       maximum: '17.0'
    @feedback = @evaluation.feedbacks.first

    @course_admin = users(:staff)
    @course_admin.administrating_courses << @evaluation.series.course
    sign_in @course_admin
  end

  test 'score errors are handled when updating feedback' do
    create :score, feedback: @feedback, score_item: @score_item1

    patch evaluation_feedback_path(@evaluation, @feedback, format: :json), params: {
      feedback: {
        scores_attributes: [
          {
            score_item_id: @score_item1.id,
            score: '12.0'
          },
          {
            score_item_id: @score_item2.id,
            score: '12.0'
          }
        ]
      }
    }

    assert_response :unprocessable_entity
  end

  test 'Scores are reset when a submission is changed' do
    create :score, feedback: @feedback, score_item: @score_item1
    @feedback.reload
    assert_equal 1, @feedback.scores.count

    s = create :submission, exercise: @feedback.exercise, user: @feedback.user

    patch evaluation_feedback_path(@evaluation, @feedback), params: {
      feedback: {
        submission_id: s.id
      }
    }
    @feedback.reload
    assert_equal s.id, @feedback.submission_id
    assert_equal 0, @feedback.scores.count
  end

  test 'A lot of scores are reset when a submission is changed' do
    score_items = (1..10).map do |i|
      create :score_item, evaluation_exercise: @feedback.evaluation_exercise,
                          description: i.to_s,
                          maximum: '10.0'
    end
    score_items.each do |si|
      create :score, feedback: @feedback, score_item: si
    end
    @feedback.reload
    assert_equal 10, @feedback.scores.count

    s = create :submission, exercise: @feedback.exercise, user: @feedback.user

    patch evaluation_feedback_path(@evaluation, @feedback), params: {
      feedback: {
        submission_id: s.id
      }
    }
    @feedback.reload
    assert_equal s.id, @feedback.submission_id
    assert_equal 0, @feedback.scores.count
  end
end
