require 'capybara/minitest'
require 'application_system_test_case'

class CoursesTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  test 'Can view courses page with working tabs' do
    zeus = create :zeus, :with_institution
    c1 = create :course, series_count: 1, activities_per_series: 1, submissions_per_exercise: 1
    c2 = create :course, series_count: 1, activities_per_series: 1, submissions_per_exercise: 1
    c3 = create :course, series_count: 1, activities_per_series: 1, submissions_per_exercise: 1
    c1.administrating_members.concat(zeus)
    c2.update(institution: zeus.institution)
    c3.update(institution: zeus.institution)

    sign_in zeus

    visit(courses_path)
    assert_selector 'd-filter-tabs li', count: 4
    assert_selector 'd-filter-tabs li:first-child a.active'
    assert_selector '#courses-table-wrapper tbody tr', count: 2

    find('d-filter-tabs').click_link 'All courses'
    assert_selector 'd-filter-tabs li:nth-of-type(3) a.active'
    assert_selector '#courses-table-wrapper tbody tr', count: 4
    find('d-filter-tabs').click_link 'My courses'
    assert_selector 'd-filter-tabs li:nth-of-type(4) a.active'
    assert_selector '#courses-table-wrapper tbody tr', count: 1
  end

  test 'Can view content of visible_for_all course when not logged in' do
    course = create :course, visibility: :visible_for_all, series_count: 3, activities_per_series: 2, submissions_per_exercise: 1
    visit(course_path(:en, course.id))
    assert_selector 'h2', text: course.name

    assert_selector '.card.series', count: 3
    assert_selector '.card.series .activity-table', count: 3
    assert_selector '.card.series .activity-table tr', count: 9
  end

  test 'Cannot view non visible_for all courses when not logged in' do
    course = create :course, visibility: :visible_for_institution, series_count: 3, activities_per_series: 2, submissions_per_exercise: 1, institution: create(:institution)
    visit(course_path(:en, course.id))
    # assert redirected to login page
    assert_selector 'h1', text: 'Sign in'

    course = create :course, visibility: :hidden, series_count: 3, activities_per_series: 2, submissions_per_exercise: 1
    visit(course_path(:en, course.id))
    # assert redirected to login page
    assert_selector 'h1', text: 'Sign in'
  end
end
