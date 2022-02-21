require 'test_helper'

class StatisticsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @course = create :course

    @course_admin = users(:staff)
    @course_admin.administrating_courses << @course
    sign_in @course_admin
  end

  test 'Exercises without submissions are included in data' do
    e1 = create :exercise
    e2 = create :exercise, submission_count: 5
    series = create :series, exercises: [e1, e2], course: @course

    # violin
    get violin_path format: :json, params: { series_id: series.id }
    results = JSON.parse response.body
    assert_equal 2, results['data'].count

    # stacked
    get stacked_status_path format: :json, params: { series_id: series.id }
    results = JSON.parse response.body
    assert_equal 2, results['data'].count

    # time series
    get timeseries_path format: :json, params: { series_id: series.id }
    results = JSON.parse response.body
    assert_equal 2, results['data'].count

    # ctimeseries
    get cumulative_timeseries_path format: :json, params: { series_id: series.id }
    results = JSON.parse response.body
    assert_equal 2, results['data'].count
  end
end
