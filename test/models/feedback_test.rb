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
    series = create :series, exercise_count: 2
    @users = [create(:user), create(:user)]
    @exercises = series.exercises
    @users.each do |u|
      series.course.enrolled_members << u
      @exercises.each do |e|
        create :submission, user: u, exercise: e, course: series.course, created_at: Time.current - 1.hour
      end
    end
    @evaluation = create :evaluation, series: series, users: @users, exercises: @exercises, deadline: Time.current
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

  test 'feedback is uncompleted on submission change' do
    feedback = @evaluation.feedbacks.where.not(submission_id: nil).first
    user = feedback.user
    exercise = feedback.exercise
    submission = create :submission, user: user, exercise: exercise, course: @evaluation.series.course

    feedback.update(completed: true)
    feedback.update(submission_id: submission.id)
    assert_not feedback.completed
  end
end
