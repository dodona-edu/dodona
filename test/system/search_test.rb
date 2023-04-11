require 'capybara/minitest'
require 'application_system_test_case'

class SearchTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  def assert_path_with_query(path, **query_params)
    page.assert_current_path path, ignore_query: true
    query_params.each do |key, value|
      page.assert_current_path(/#{key}=#{value}/)
    end
  end

  test 'Browser history updates current entry when searching' do
    32.times do |i|
      create :exercise, name_en: "test #{i}", name_nl: "test #{i}"
    end
    sign_in create(:zeus)
    visit root_path
    visit activities_path
    assert_path_with_query activities_path
    find('d-search-field input').send_keys 'test'
    assert_path_with_query activities_path, filter: 'test'
    find('.next_page').click
    assert_path_with_query activities_path, filter: 'test', page: 2
    page.go_back
    assert_path_with_query activities_path, filter: 'test'
    page.go_back
    page.assert_current_path root_path
    page.go_forward
    assert_path_with_query activities_path, filter: 'test'
    page.go_forward
    assert_path_with_query activities_path, filter: 'test', page: 2
    find('d-search-field input').send_keys 's'
    assert_path_with_query activities_path, filter: 'tests'
    page.go_back
    assert_path_with_query activities_path, filter: 'test', page: 2
    page.go_forward
    assert_path_with_query activities_path, filter: 'tests'
  end

  test 'Going to a page with search does not create an extra history entry' do
    assert_equal 1, page.evaluate_script('window.history.length')
    sign_in create(:zeus)
    visit root_path
    assert_equal 2, page.evaluate_script('window.history.length')
    click_on 'Toggle drawer'
    click_on 'Exercises'
    page.assert_current_path activities_path
    assert_equal 3, page.evaluate_script('window.history.length')
    page.go_back
    page.assert_current_path root_path
  end

end
