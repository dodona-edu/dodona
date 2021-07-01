require 'test_helper'

class ScoreItemPolicyTest < ActiveSupport::TestCase
  setup do
    @evaluation = create :evaluation, :with_submissions
    @staff_member = create :staff
    @evaluation.series.course.administrating_members << @staff_member

    exercise = @evaluation.evaluation_exercises.first
    @feedback = @evaluation.feedbacks.first
    @score_item1 = create :score_item, evaluation_exercise: exercise, visible: true
    @score_item2 = create :score_item, evaluation_exercise: exercise, visible: false
  end

  test 'zeus can see all score items' do
    # Not completed feedbacks
    zeus = create :zeus
    assert_equal [@score_item1, @score_item2].sort, Pundit.policy_scope!(zeus, ScoreItem).sort
    # Completed feedbacks
    @evaluation.update!(released: true)
    assert_equal [@score_item1, @score_item2].sort, Pundit.policy_scope!(zeus, ScoreItem).sort
  end

  test 'course administrator can seel all score items for own course' do
    assert_equal [@score_item1, @score_item2].sort, Pundit.policy_scope!(@staff_member, ScoreItem).sort
    @evaluation.update!(released: true)
    assert_equal [@score_item1, @score_item2].sort, Pundit.policy_scope!(@staff_member, ScoreItem).sort
  end

  test 'student can only see released, visible score items' do
    random = create :user
    assert_equal [], Pundit.policy_scope!(@feedback.evaluation_user.user, ScoreItem)
    assert_equal [], Pundit.policy_scope!(random, Score)

    @evaluation.update!(released: true)
    assert_equal [@score_item1], Pundit.policy_scope!(@feedback.evaluation_user.user, ScoreItem)
    assert_equal [], Pundit.policy_scope!(random, Score)
  end

  test 'not logged in can see nothing' do
    assert_equal [], Pundit.policy_scope!(nil, ScoreItem)
    @evaluation.update!(released: true)
    assert_equal [], Pundit.policy_scope!(nil, ScoreItem)
  end
end
