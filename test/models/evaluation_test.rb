# == Schema Information
#
# Table name: evaluations
#
#  id         :bigint           not null, primary key
#  series_id  :integer
#  released   :boolean          default(FALSE), not null
#  deadline   :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'test_helper'

class EvaluationTest < ActiveSupport::TestCase
  setup do
    @evaluation = create :evaluation, :with_submissions, user_count: 2
    @exercise1 = @evaluation.evaluation_exercises.first
    @exercise2 = @evaluation.evaluation_exercises.second
    @feedback1 = @exercise1.feedbacks.first
    @feedback2 = @exercise1.feedbacks.second
    @feedback3 = @exercise2.feedbacks.first
  end

  def add_score_items
    @item1 = create :score_item, maximum: '12.0', evaluation_exercise: @exercise1
    @item2 = create :score_item, maximum: '5.0', evaluation_exercise: @exercise1
    @item3 = create :score_item, maximum: '5.0', evaluation_exercise: @exercise2
  end

  def add_scores
    # First user, first exercise, score item 1
    create :score, score_item: @item1, score: '11', feedback: @feedback1
    # First user, first exercise, score item 2
    create :score, score_item: @item2, score: '4', feedback: @feedback1
    # Second user, first exercise, score item 1
    create :score, score_item: @item1, score: '12', feedback: @feedback2
    # Second user, first exercise, score item 2
    create :score, score_item: @item2, score: '0', feedback: @feedback2
    # First user, second exercise, score item 1
    create :score, score_item: @item3, score: '5', feedback: @feedback3
  end

  test 'max and average are calculated correctly' do
    # no max or average
    assert_nil @evaluation.maximum_score
    assert_nil @evaluation.average_score_sum

    add_score_items

    # max but no average
    assert_equal BigDecimal('22'), @evaluation.reload.maximum_score
    assert_nil @evaluation.average_score_sum

    add_scores

    # max and average
    assert_equal BigDecimal('22'), @evaluation.reload.maximum_score
    assert_equal BigDecimal('18.5'), @evaluation.average_score_sum
  end



  test 'Scores are set if a user is added' do
    evaluation = create :evaluation, :with_submissions
    evaluation.evaluation_exercises.each do |ee|
      create :score_item, evaluation_exercise: ee,
             description: 'First item',
             maximum: '10.0'
      create :score_item, evaluation_exercise: ee,
             description: 'Second item',
             maximum: '17.0'
    end

    course = evaluation.series.course
    exercise = evaluation.evaluation_exercises.first.exercise

    user = create :user
    user.enrolled_courses << course
    create :correct_submission, user: user, exercise: exercise, course: course, created_at: evaluation.deadline - 1.hour

    Current.user = create :zeus
    assert_difference 'Feedback.count', evaluation.evaluation_exercises.count do
      evaluation.update(users: evaluation.users + [user])
    end

    evaluation_user = EvaluationUser.find_by(user: user, evaluation: evaluation)
    assert_not_nil evaluation_user

    # We have a submission for the first exercise, so it should not be completed, with no scores set
    first_feedback = Feedback.find_by(evaluation_user: evaluation_user, evaluation_exercise: evaluation.evaluation_exercises.first)
    assert_not_nil first_feedback
    assert_not first_feedback.completed?
    assert_equal 2, first_feedback.score_items.count
    assert_equal 0, first_feedback.scores.count

    # We have no submission for the second exercise, so it should be completed, with all scores set to 0
    second_feedback = Feedback.find_by(evaluation_user: evaluation_user, evaluation_exercise: evaluation.evaluation_exercises.second)
    assert_not_nil second_feedback
    assert second_feedback.completed?
    assert_equal 2, second_feedback.score_items.count
    assert_equal 2, second_feedback.scores.count
    assert_equal 0, second_feedback.scores.first.score
    assert_equal 0, second_feedback.scores.second.score
  end
end
