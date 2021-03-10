# == Schema Information
#
# Table name: feedbacks
#
#  id                     :bigint           not null, primary key
#  submission_id          :integer
#  evaluation_id          :bigint
#  evaluation_user_id     :bigint
#  evaluation_exercise_id :bigint
#  completed              :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
require 'test_helper'

class FeedbackTest < ActiveSupport::TestCase
  setup do
    @evaluation = create :evaluation, :with_submissions, user_count: 2
    @users = @evaluation.users
    @exercises = @evaluation.series.exercises
    @user_count = @users.count
    @exercise_count = @exercises.count
    @zeus = create :zeus
  end

  test 'Appropriate amount of feedbacks are created when making a session and when updating' do
    assert @user_count > 1
    assert @exercise_count > 1
    assert_equal @user_count * @exercise_count, @evaluation.feedbacks.count

    user_to_remove = @users.sample

    params = {
      exercises: @exercises,
      users: @users - [user_to_remove]
    }
    @evaluation.update(params)

    assert_equal (@user_count - 1) * @exercise_count, @evaluation.feedbacks.count

    exercise_to_remove = @exercises.sample

    params = {
      exercises: @exercises - [exercise_to_remove],
      users: @users - [user_to_remove]
    }
    @evaluation.update(params)
    assert_equal (@user_count - 1) * (@exercise_count - 1), @evaluation.feedbacks.count
  end

  test 'annotations linked to old feedback session are deleted upon submission change' do
    feedback = @evaluation.feedbacks.where.not(submission_id: nil).first
    user = feedback.user
    exercise = feedback.exercise
    submission = create :submission, user: user, exercise: exercise, course: @evaluation.series.course

    feedback.submission.annotations.create(evaluation_id: @evaluation.id, annotation_text: 'blah', line_nr: 0, user: @zeus)

    feedback.update(submission_id: submission.id)
    assert_equal 0, submission.annotations.count
  end

  test 'score calculations are correct' do
    feedback = @evaluation.feedbacks.where.not(submission_id: nil).first
    si1 = create :score_item, evaluation_exercise: feedback.evaluation_exercise
    si2 = create :score_item, evaluation_exercise: feedback.evaluation_exercise
    s1 = create :score, feedback: feedback, score: '5.0', score_item: si1
    s2 = create :score, feedback: feedback, score: '6.0', score_item: si2

    assert feedback.score == s1.score + s2.score
    assert feedback.maximum_score == s1.score_item.maximum + s2.score_item.maximum
  end
end
