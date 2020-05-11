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
    @review_session = create :review_session
    @zeus = create :zeus
  end

  test 'Appropriate amount of reviews are created when making a session and when updating' do
    users = @review_session.series.course.submissions.where(exercise: @review_session.series.exercises).map(&:user).uniq
    user_count = users.count
    exercises = @review_session.series.exercises
    exercise_count = exercises.count

    assert_equal user_count * exercise_count, @review_session.reviews.count

    user_to_remove = users.sample

    params = {
      exercises: exercises,
      users: users - [user_to_remove]
    }
    @review_session.update(params)

    assert_equal (user_count - 1) * exercise_count, @review_session.reviews.count

    exercise_to_remove = exercises.sample

    params = {
      exercises: exercises - [exercise_to_remove],
      users: users - [user_to_remove]
    }
    @review_session.update(params)
    assert_equal (user_count - 1) * (exercise_count - 1), @review_session.reviews.count
  end
end
