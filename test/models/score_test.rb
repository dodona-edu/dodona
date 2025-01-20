# == Schema Information
#
# Table name: scores
#
#  id                 :bigint           not null, primary key
#  score              :decimal(5, 2)    not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  feedback_id        :bigint           not null
#  last_updated_by_id :integer          not null
#  score_item_id      :bigint           not null
#
# Indexes
#
#  index_scores_on_feedback_id                    (feedback_id)
#  index_scores_on_last_updated_by_id             (last_updated_by_id)
#  index_scores_on_score_item_id                  (score_item_id)
#  index_scores_on_score_item_id_and_feedback_id  (score_item_id,feedback_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (feedback_id => feedbacks.id)
#  fk_rails_...  (last_updated_by_id => users.id)
#  fk_rails_...  (score_item_id => score_items.id)
#
require 'test_helper'

class ScoreTest < ActiveSupport::TestCase
  setup do
    @evaluation = create :evaluation, :with_submissions
    exercise = @evaluation.evaluation_exercises.first
    @score_item1 = create :score_item, evaluation_exercise: exercise,
                                       description: 'First item',
                                       maximum: '10.0'
    @score_item2 = create :score_item, evaluation_exercise: exercise,
                                       description: 'Second item',
                                       maximum: '17.0'
    @feedback = @evaluation.feedbacks.first
    @feedback.update!(completed: false)
  end

  test 'adding last score item should complete feedback' do
    assert_not @feedback.completed?
    create :score, feedback: @feedback, score_item: @score_item1

    assert_not @feedback.completed?
    create :score, feedback: @feedback, score_item: @score_item2

    assert_predicate @feedback, :completed?
  end

  test 'deleting score should uncomplete feedback' do
    @feedback.update!(completed: true)
    score = create :score, feedback: @feedback, score_item: @score_item1
    create :score, feedback: @feedback, score_item: @score_item2

    assert_predicate @feedback, :completed?
    score.destroy!

    assert_not @feedback.completed?
  end

  test 'deleting all score items does not uncomplete feedback' do
    @feedback.update!(completed: true)
    create :score, feedback: @feedback, score_item: @score_item1
    create :score, feedback: @feedback, score_item: @score_item2

    @score_item1.destroy!

    assert_predicate @feedback, :completed?
    @score_item2.destroy!

    assert_predicate @feedback, :completed?
    assert_empty @feedback.score_items
  end

  test 'duplicate scores are rejected' do
    create :score, feedback: @feedback, score_item: @score_item1
    score = build :score, feedback: @feedback, score_item: @score_item1

    assert_not score.save
  end

  test 'out of bounds values are rejected' do
    score = build :score, feedback: @feedback, score_item: @score_item1, score: BigDecimal('-1')

    assert_not score.save

    score.score = BigDecimal('11.0')

    assert_not score.save
  end
end
