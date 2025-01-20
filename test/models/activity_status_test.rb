# == Schema Information
#
# Table name: activity_statuses
#
#  id                          :bigint           not null, primary key
#  accepted                    :boolean          default(FALSE), not null
#  accepted_before_deadline    :boolean          default(FALSE), not null
#  solved                      :boolean          default(FALSE), not null
#  started                     :boolean          default(FALSE), not null
#  solved_at                   :datetime
#  activity_id                 :integer          not null
#  series_id                   :integer
#  user_id                     :integer          not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  last_submission_id          :integer
#  last_submission_deadline_id :integer
#  best_submission_id          :integer
#  best_submission_deadline_id :integer
#  series_id_non_nil           :integer          not null
#
require 'test_helper'

class ActivityStatusTest < ActiveSupport::TestCase
  test 'submitting to an exercise should update all activity statuses' do
    course = courses(:course1)
    series = create :series, course: course, exercise_count: 1
    activity = series.activities.first
    user = users(:student)
    as1 = create :activity_status, user: user, activity: activity, series: nil
    as2 = create :activity_status, user: user, activity: activity, series: series

    assert_not as1.started
    assert_not as2.started

    create :submission, exercise: activity, course: course, status: :correct, user: user

    as1.reload
    as2.reload

    assert as1.started
    assert as2.started
  end

  test 'should not be able to create two activity_statuses with series_id nil' do
    activity = exercises(:python_exercise)
    user = users(:student)
    ActivityStatus.create(user: user, activity: activity, series: nil)
    ActivityStatus.create(user: user, activity: activity, series: nil)

    assert_equal 1, ActivityStatus.count
  end

  test 'activity status should always exist if a user has a submission' do
    user = users(:student)
    course = courses(:course1)
    series = create :series, course: course, exercise_count: 1
    activity = series.activities.first
    create :submission, exercise: activity, course: course, status: :correct, user: user

    assert_not_nil ActivityStatus.find_by(user: user, activity: activity, series: series)
    assert_not_nil ActivityStatus.find_by(user: user, activity: activity, series: nil)
  end

  test 'activity status should always exist if a user has a activity read state' do
    user = users(:student)
    course = courses(:course1)
    series = create :series, course: course, content_page_count: 1
    activity = series.activities.first
    create :activity_read_state, activity: activity, course: course, user: user

    assert_not_nil ActivityStatus.find_by(user: user, activity: activity, series: series)
    assert_not_nil ActivityStatus.find_by(user: user, activity: activity, series: nil)
  end

  test 'Activity status should be destroyed when series membership is destroyed' do
    user = users(:student)
    course = courses(:course1)
    series = create :series, course: course, content_page_count: 1
    activity = series.activities.first
    create :activity_read_state, activity: activity, course: course, user: user

    assert_not_nil ActivityStatus.find_by(user: user, activity: activity, series: series)
    assert_not_nil ActivityStatus.find_by(user: user, activity: activity, series: nil)
    SeriesMembership.find_by(series: series, activity: activity).destroy

    assert_nil ActivityStatus.find_by(user: user, activity: activity, series: series)
    assert_not_nil ActivityStatus.find_by(user: user, activity: activity, series: nil)
  end

  test 'Activity status should be created when series membership is created' do
    user = users(:student)
    course = courses(:course1)
    series = create :series, course: course, content_page_count: 1
    series2 = create :series, course: course
    activity = series.activities.first
    create :activity_read_state, activity: activity, course: course, user: user

    assert_nil ActivityStatus.find_by(user: user, activity: activity, series: series2)
    SeriesMembership.create(series: series2, activity: activity)

    assert_not_nil ActivityStatus.find_by(user: user, activity: activity, series: series2)
  end

  test 'Activity status should be updated when series deadline is updated' do
    user = users(:student)
    course = courses(:course1)
    series = create :series, course: course, content_page_count: 1, deadline: 1.week.from_now
    activity = series.activities.first
    create :activity_read_state, activity: activity, course: course, user: user

    assert_not_nil ActivityStatus.find_by(user: user, activity: activity, series: series)
    assert ActivityStatus.find_by(user: user, activity: activity, series: series).accepted_before_deadline
    series.deadline = 1.week.ago
    series.save

    assert_not_nil ActivityStatus.find_by(user: user, activity: activity, series: series)
    assert_not ActivityStatus.find_by(user: user, activity: activity, series: series).accepted_before_deadline
  end
end
