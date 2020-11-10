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
    course = create :course
    series = create :series, course: course, exercise_count: 1
    activity = series.activities.first
    user = create :user
    as1 = create :activity_status, user: user, activity: activity, series: nil
    as2 = create :activity_status, user: user, activity: activity, series: series
    assert_not as1.started
    assert_not as2.started

    create :submission, activity: activity, course: course, status: :correct, user: user

    as1.reload
    as2.reload
    assert as1.started
    assert as2.started
  end

  test 'should not be able to create two activity_statuses with series_id nil' do
    activity = create :exercise
    user = create :user
    ActivityStatus.create(user: user, activity: activity, series: nil)
    ActivityStatus.create(user: user, activity: activity, series: nil)
    assert_equal 1, ActivityStatus.count
  end
end
