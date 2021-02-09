require 'test_helper'

class UserPolicyTest < ActiveSupport::TestCase
  setup do
    @staff_member = create :staff
    series = create :series, exercise_count: 2
    series.course.administrating_members << @staff_member
    @users = [create(:user)]
    @exercises = series.exercises
    @users.each do |u|
      series.course.enrolled_members << u
      @exercises.each do |e|
        create :correct_submission, user: u, exercise: e, course: series.course, created_at: Time.current - 1.hour
      end
    end
    @evaluation = create :evaluation, series: series, users: @users, exercises: @exercises, deadline: Time.current - 1.second

    exercise = @evaluation.evaluation_exercises.first
    @feedback = @evaluation.feedbacks.first
    @score1 = create :score, rubric: create(:rubric, evaluation_exercise: exercise, visible: true), feedback: @feedback
    @score2 = create :score, rubric: create(:rubric, evaluation_exercise: exercise, visible: false), feedback: @feedback
  end

  test 'zeus can see all scores' do
    # Not completed feedbacks
    zeus = create :zeus
    assert_equal [@score1, @score2].sort, Pundit.policy_scope!(zeus, Score).sort
    # Completed feedbacks
    @evaluation.update!(released: true)
    assert_equal [@score1, @score2].sort, Pundit.policy_scope!(zeus, Score).sort
  end

  test 'course administrator can seel all scores for own course' do
    assert_equal [@score1, @score2].sort, Pundit.policy_scope!(@staff_member, Score).sort
    @evaluation.update!(released: true)
    assert_equal [@score1, @score2].sort, Pundit.policy_scope!(@staff_member, Score).sort
  end

  test 'staff cannot view scores for other courses' do
    staff = create :staff
    assert_equal [], Pundit.policy_scope!(staff, Score)
    @evaluation.update!(released: true)
    assert_equal [], Pundit.policy_scope!(staff, Score)
  end

  test 'student can only see released, visible scores' do
    random = create :user
    assert_equal [], Pundit.policy_scope!(@feedback.evaluation_user.user, Score)
    assert_equal [], Pundit.policy_scope!(random, Score)

    @evaluation.update!(released: true)
    assert_equal [@score1], Pundit.policy_scope!(@feedback.evaluation_user.user, Score)
    assert_equal [], Pundit.policy_scope!(random, Score)
  end
end
