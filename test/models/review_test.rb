# == Schema Information
#
# Table name: reviews
#
#  id                 :bigint           not null, primary key
#  submission_id      :integer
#  review_session_id  :bigint
#  review_user_id     :bigint
#  review_exercise_id :bigint
#  completed          :boolean          default(FALSE), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
require 'test_helper'

class ReviewTest < ActiveSupport::TestCase
  setup do
    series = create :series, exercise_count: 2
    @users = [create(:user), create(:user)]
    @exercises = series.exercises
    @users.each do |u|
      series.course.enrolled_members << u
      @exercises.each do |e|
        create :submission, user: u, exercise: e, course: series.course
      end
    end
    @review_session = create :review_session, series: series, users: @users, exercises: @exercises, deadline: Time.zone.now + 1.hour
    @user_count = @users.count
    @exercise_count = @exercises.count
    @zeus = create :zeus
  end

  test 'Appropriate amount of reviews are created when making a session and when updating' do
    assert @user_count > 1
    assert @exercise_count > 1
    assert_equal @user_count * @exercise_count, @review_session.reviews.count

    user_to_remove = @users.sample

    params = {
      exercises: @exercises,
      users: @users - [user_to_remove]
    }
    @review_session.update(params)

    assert_equal (@user_count - 1) * @exercise_count, @review_session.reviews.count

    exercise_to_remove = @exercises.sample

    params = {
      exercises: @exercises - [exercise_to_remove],
      users: @users - [user_to_remove]
    }
    @review_session.update(params)
    assert_equal (@user_count - 1) * (@exercise_count - 1), @review_session.reviews.count
  end

  test 'annotations linked to old review session are deleted upon submission change' do
    review = @review_session.reviews.where.not(submission_id: nil).first
    user = review.review_user.user
    exercise = review.review_exercise.exercise
    submission = create :submission, user: user, exercise: exercise, course: @review_session.series.course

    review.submission.annotations.create(review_session_id: @review_session.id, annotation_text: 'blah', line_nr: 0, user: @zeus)

    review.update(submission_id: submission.id)
    assert_equal 0, submission.annotations.count
  end
end
