require 'test_helper'

class LtiHelperTest < ActionDispatch::IntegrationTest
  include LtiHelper

  setup do
    @course = create :course
    @series = create :series, course: @course, exercise_count: 2
  end

  test 'resource link is for course if course is selected' do
    params = {
      lti: {
        course: @course.id
      }
    }

    result = lti_resource_links_from(params)
    assert_equal(1, result.length)
    item = result[0]
    assert_equal(@course.name, item.title)
    assert_equal(lti_course_url(@course), item.url)
  end

  test 'resource link is for hidden course if course is selected' do
    @course.visibility = :hidden
    @course.save
    params = {
      lti: {
        course: @course.id
      }
    }

    result = lti_resource_links_from(params)
    assert_equal(1, result.length)
    item = result[0]
    assert_equal(@course.name, item.title)
    assert_equal(lti_course_url(@course), item.url)
  end

  test 'resource link is for series if series is selected' do
    params = {
      lti: {
        course: @course.id,
        series: @series.id
      }
    }

    result = lti_resource_links_from(params)
    assert_equal(1, result.length)
    item = result[0]
    assert_equal(@series.name, item.title)
    assert_equal(lti_series_url(@course.id, @series), item.url)
  end

  test 'resource link is for hidden series if series is selected' do
    @series.visibility = :hidden
    @series.save
    params = {
      lti: {
        course: @course.id,
        series: @series.id
      }
    }

    result = lti_resource_links_from(params)
    assert_equal(1, result.length)
    item = result[0]
    assert_equal(@series.name, item.title)
    assert_equal(lti_series_url(@course.id, @series), item.url)
  end

  test 'resource link is for activity if activity is selected' do
    activity = @series.activities.first
    params = {
      lti: {
        course: @course.id,
        series: @series.id,
        activities: [activity.id]
      }
    }

    result = lti_resource_links_from(params)
    assert_equal(1, result.length)
    item = result[0]
    assert_equal(activity.name, item.title)
    assert_equal(lti_activity_url(@course.id, @series.id, activity), item.url)
  end

  test 'multiple activities are supported' do
    params = {
      lti: {
        course: @course.id,
        series: @series.id,
        activities: @series.activities.map(&:id)
      }
    }

    result = lti_resource_links_from(params)
    assert_equal(2, result.length)
  end
end
