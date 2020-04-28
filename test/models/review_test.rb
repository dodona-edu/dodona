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
    user_ids = @review_session.series.course.submissions.where(exercise: @review_session.series.exercises).map(&:user_id).uniq
    user_count = user_ids.count
    exercise_ids = @review_session.series.exercises.map(&:id)
    exercise_count = exercise_ids.count

    assert_equal user_count * exercise_count, @review_session.reviews.count

    user_id_to_remove = user_ids.sample

    params = {
      review_session: {
        exercises: exercise_ids,
        users: user_ids - [user_id_to_remove],
        released: false
      }
    }
    @review_session.update_session(params)

    assert_equal (user_ids.count - 1) * exercise_count, @review_session.reviews.count

    exercise_id_to_remove = exercise_ids.sample

    params = {
      review_session: {
        exercises: exercise_ids - [exercise_id_to_remove],
        users: user_ids - [user_id_to_remove],
        released: false
      }
    }
    @review_session.update_session(params)
    assert_equal (user_ids.count - 1) * (exercise_count - 1), @review_session.reviews.count
  end
end
