# == Schema Information
#
# Table name: activity_read_states
#
#  id          :bigint           not null, primary key
#  activity_id :integer          not null
#  course_id   :integer
#  user_id     :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'test_helper'

class ActivityReadStateTest < ActiveSupport::TestCase
  test 'only one read state allowed for a combination of course - user - activity' do
    series = create :series, content_page_count: 1
    user = create :user, enrolled_courses: [series.course]

    read_state = create :activity_read_state,
                        user: user,
                        course: series.course,
                        activity: series.content_pages.first

    assert_not_nil read_state
    assert read_state.valid?

    second_read_state = build :activity_read_state,
                              user: user,
                              course: series.course,
                              activity: series.content_pages.first

    assert_not second_read_state.valid?

    # but we can make a new read state outside the course
    second_read_state.course = nil
    assert second_read_state.valid?
  end
end
