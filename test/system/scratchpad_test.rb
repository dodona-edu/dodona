require 'capybara/minitest'
require 'application_system_test_case'

class ScratchpadTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  setup do
    @zeus = create(:zeus)
    @course = create :course
    @exercise = create(:exercise, programming_language_id: ProgrammingLanguage.where(name: 'python').first)
    puts @exercise.inspect
    puts @exercise.programming_language&.inspect
    @course.series << create(:series)
    @course.series.first.activities << @exercise

    sign_in @zeus
  end

  test 'Scratchpad can correctly run code' do
    visit(course_activity_path(course_id: @course.id, id: @exercise.id))
    assert_selector '#scratchpad-offcanvas-show-btn'
    find('#scratchpad-offcanvas-show-btn').click

    assert_selector 'scratchpad-editor-wrapper'
    find('scratchpad-editor-wrapper').send_keys 'print("Hello World!")'

    find('__papyros-run-code-btn').click
    begin
      output_area = find('scratchpad-output-wrapper')
      within output_area do
        wait_until { output_area.find('span', 'Hello World!').visible? }
      end
    rescue Capybara::TimeoutError
      flunk 'Expected Hello World! to be printed.'
    end
  end
end
