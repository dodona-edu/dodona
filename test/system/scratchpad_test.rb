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
    @programming_language = create(:programming_language, name: 'python')
    @exercise = create(:exercise, programming_language_id: @programming_language.id)
    @course.series << create(:series)
    @course.series.first.activities << @exercise

    sign_in @zeus
    visit(course_activity_path(course_id: @course.id, id: @exercise.id))
    assert_selector '#scratchpad-offcanvas-show-btn'
  end

  test 'Scratchpad can run Hello World!' do
    find('#scratchpad-offcanvas-show-btn').click
    assert_selector '.cm-editor'
    # Focus editor
    find('.cm-editor').click
    find('.cm-content').send_keys 'print("Hello World!")'
    find('#__papyros-run-code-btn').click
    output_area = find('#scratchpad-output-wrapper')
    output_area.find('span', text: 'Hello World!')
  end

  test 'Scratchpad can process user input' do
    find('#scratchpad-offcanvas-show-btn').click
    assert_selector '.cm-editor'
    # Focus editor
    find('.cm-editor').click
    find('.cm-content').send_keys 'print(input())'
    find('#__papyros-run-code-btn').click
    scratchpad_input = 'Echo'
    find_field('#__papyros-code-input-area', disabled: false).send_keys scratchpad_input
    find_button('#__papyros-send-input-btn', disabled: false).click
    output_area = find('#scratchpad-output-wrapper')
    output_area.find('span', text: scratchpad_input)
  end
end
