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

  test 'Can toggle between exercises list and visualisations' do
    assert_selector '.stats-active', count: 0
    toggle = find('.mdi.mdi-chart-line')

    toggle.click
    assert_selector '.stats-active', count: 1 # card should have received this class
    assert_selector '.mdi.mdi-chart-line', count: 0 # button class should have been replaced
    assert_selector '.mdi.mdi-format-list-bulleted', count: 1

    # should be able to toggle back
    toggle.click
    assert_selector '.stats-active', count: 0 # this class should have been removed
    assert_selector '.mdi.mdi-chart-line', count: 1 # button class should have been replaced
    assert_selector '.mdi.mdi-format-list-bulleted', count: 0

    # make sure nothing broke when toggling back
    toggle.click
    assert_selector '.stats-active', count: 1 # card should have received this class
    assert_selector '.mdi.mdi-chart-line', count: 0 # button class should have been replaced
    assert_selector '.mdi.mdi-format-list-bulleted', count: 1
  end

  test 'Can toggle between types of graphs' do
    find('.mdi.mdi-chart-line').click
    title = find('.graph-title > span')

    assert_selector '.btn.annotation-toggle.violin.active' # violin should be active by default
    assert_selector '.btn.annotation-toggle.active', count: 1 # only one buttom active at a time
    within title do
      assert_text 'Number of submissions per user'
    end

    find('.btn.annotation-toggle.stacked').click
    assert_selector '.btn.annotation-toggle.stacked.active'
    assert_selector '.btn.annotation-toggle.active', count: 1 # only one active
    within title do
      assert_text 'Distribution of submission statuses'
    end

    find('.btn.annotation-toggle.timeseries').click
    assert_selector '.btn.annotation-toggle.timeseries.active'
    assert_selector '.btn.annotation-toggle.active', count: 1
    within title do
      assert_text 'Submissions over time'
    end

    find('.btn.annotation-toggle.ctimeseries').click
    assert_selector '.btn.annotation-toggle.ctimeseries.active'
    assert_selector '.btn.annotation-toggle.active', count: 1
    within title do
      assert_text 'Users with at least one correct submission'
    end

    find('.btn.annotation-toggle.violin').click
    assert_selector '.btn.annotation-toggle.violin.active' # violin should be active by default
    assert_selector '.btn.annotation-toggle.active', count: 1
    within title do
      assert_text 'Number of submissions per user'
    end
  end
end
