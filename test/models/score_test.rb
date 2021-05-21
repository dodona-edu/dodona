# == Schema Information
#
# Table name: scores
#
#  id                 :bigint           not null, primary key
#  score_item_id      :bigint           not null
#  feedback_id        :bigint           not null
#  score              :decimal(5, 2)    not null
#  last_updated_by_id :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
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
    assert @feedback.completed?
  end

  test 'deleting score should uncomplete feedback' do
    @feedback.update!(completed: true)
    score = create :score, feedback: @feedback, score_item: @score_item1
    create :score, feedback: @feedback, score_item: @score_item2
    assert @feedback.completed?
    score.destroy!
    assert_not @feedback.completed?
  end

  test 'deleting all score items does not uncomplete feedback' do
    @feedback.update!(completed: true)
    create :score, feedback: @feedback, score_item: @score_item1
    create :score, feedback: @feedback, score_item: @score_item2

    @score_item1.destroy!
    assert @feedback.completed?
    @score_item2.destroy!
    assert @feedback.completed?
    assert_empty @feedback.score_items
  end

  test 'duplicate scores are rejected' do
    create :score, feedback: @feedback, score_item: @score_item1
    score = build :score, feedback: @feedback, score_item: @score_item1

    assert_not score.save
  end
end
