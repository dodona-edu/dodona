require 'test_helper'

class ActivityHelperTest < ActiveSupport::TestCase
  include ActivityHelper
  include Rails.application.routes.url_helpers

  setup do
    course = create :course
    @series = create :series, course: course, exercise_count: 3
  end

  test 'previous activity at beginning of series should be nil' do
    current_exercise = @series.exercises[0]
    previous_ex_path, = previous_next_activity_path(@series, current_exercise)
    assert_nil previous_ex_path
  end

  test 'previous activity midway series' do
    current_exercise = @series.exercises[1]
    previous_exercise = @series.exercises[0]

    previous_exercise_path = course_series_activity_path(I18n.locale, @series.course_id, @series, previous_exercise)
    previous_ex_path, = previous_next_activity_path(@series, current_exercise)
    assert_equal previous_exercise_path, previous_ex_path
  end

  test 'next activity midway series' do
    current_exercise = @series.exercises[1]
    next_exercise = @series.exercises[2]

    next_exercise_path = course_series_activity_path(I18n.locale, @series.course_id, @series, next_exercise)
    _, next_ex_path = previous_next_activity_path(@series, current_exercise)
    assert_equal next_exercise_path, next_ex_path
  end

  test 'next activity at end of series should be nil' do
    current_exercise = @series.exercises[2]
    _, next_ex_path = previous_next_activity_path(@series, current_exercise)
    assert_nil next_ex_path
  end
end
