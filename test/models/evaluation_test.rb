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
end
