require 'capybara/minitest'
require 'application_system_test_case'

class SeriesVisualisationsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  setup do
    @zeus = create(:zeus)
    @c1 = create :course, series_count: 1, activities_per_series: 1, submissions_per_exercise: 1
    @c1.administrating_members.concat(@zeus)

    sign_in @zeus
    visit(course_path(id: @c1.id))
  end

  test 'Can toggle between types of graphs' do
    assert_no_selector '.btn.graph-toggle.active .violin'

    find('.btn.graph-toggle .violin').click

    title = find('.graph-title > span')

    assert_selector '.btn.graph-toggle.active .violin'
    within title do
      assert_text 'Number of submissions per user'
    end

    find('.btn.graph-toggle .stacked-bar-chart').click
    assert_selector '.btn.graph-toggle.active .stacked-bar-chart'
    within title do
      assert_text 'Distribution of submission statuses'
    end

    # find('.btn.graph-toggle.timeseries').click
    # assert_selector '.btn.graph-toggle.timeseries.active'
    # within title do
    #   assert_text 'Submissions over time'
    # end

    find('.btn.graph-toggle .stacked-line-chart').click
    assert_selector '.btn.graph-toggle.active .stacked-line-chart'
    within title do
      assert_text 'Users with at least one correct submission'
    end

    find('.btn.graph-toggle .violin').click
    assert_selector '.btn.graph-toggle.active .violin'
    within title do
      assert_text 'Number of submissions per user'
    end
  end
end
