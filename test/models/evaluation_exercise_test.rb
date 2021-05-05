# == Schema Information
#
# Table name: evaluation_exercises
#
#  id            :bigint           not null, primary key
#  evaluation_id :bigint
#  exercise_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  visible_score :boolean          default(TRUE), not null
#
require 'test_helper'

class EvaluationExerciseTest < ActiveSupport::TestCase
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

  test 'score items give correct maximum score' do
    add_score_items

    assert_equal BigDecimal('17'), @exercise1.maximum_score
    assert_equal BigDecimal('5'), @exercise2.maximum_score
  end

  test 'scores give correct maximum score' do
    add_score_items
    add_scores

    assert_equal BigDecimal('17'), @exercise1.maximum_score
    assert_equal BigDecimal('5'), @exercise2.maximum_score
  end

  test 'no scores result in no maximum' do
    assert_nil @exercise1.maximum_score
    assert_nil @exercise2.maximum_score
  end

  test 'no scores result in no average' do
    assert_nil @exercise1.average_score
    assert_nil @exercise2.average_score
  end

  test 'score items result in no average' do
    add_score_items

    assert_nil @exercise1.average_score
    assert_nil @exercise2.average_score
  end

  test 'scores give correct averages' do
    add_score_items
    add_scores

    # This exercise has two users, each with scores.
    # ((11+4) + (12+0)) / 2 = (15 + 12) / 2 = 27 / 2 = 13.5
    assert_equal BigDecimal('13.5'), @exercise1.average_score
    # This exercise has two users, but only one feedback with a score.
    # (5+0) / 1 = 5 / 1 = 5
    assert_equal BigDecimal('5'), @exercise2.average_score
  end
end
