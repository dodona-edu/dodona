require 'capybara/minitest'
require 'application_system_test_case'

class ScratchpadTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  setup do
    @zeus = create :zeus
    @course = create :course
    @programming_language = create :programming_language, name: 'python'
    @exercise = create :exercise, programming_language_id: @programming_language.id
    @course.series << create(:series)
    @course.series.first.activities << @exercise

    sign_in @zeus

    # Open Papyros ready for use
    visit(course_activity_path(course_id: @course.id, id: @exercise.id))
    assert_selector '#scratchpad-offcanvas-show-btn'
    find_by_id('scratchpad-offcanvas-show-btn').click
  end

  def codemirror_send_keys(parent, code)
    # Focus editor
    parent.find('.cm-editor').click
    parent.find('.cm-content').send_keys code
    sleep(0.5)
  end

  # Set code in the editor and run it
  def run_code(code)
    codemirror_send_keys(find_by_id('scratchpad-editor-wrapper'), code)
    find_button('__papyros-run-code-btn', disabled: false).click
  end

  test 'Scratchpad can run code' do
    ## Hello World!
    code = "print(\"Hello World!\")\n"
    run_code code
    output_area = find_by_id('scratchpad-output-wrapper')
    # First run, so wait longer for output to appear
    output_area.find('span', text: 'Hello World!', wait: 20)

    # Scratchpad can process user input in interactive mode
    scratchpad_input = 'Echo'
    code = "print(input())\n"
    run_code code
    # Enter the input during the run
    find_field('__papyros-code-input-area', disabled: false).send_keys scratchpad_input
    find_button('__papyros-send-input-btn', disabled: false).click

    output_area.find('span', text: scratchpad_input)

    # Scratchpad can process user input in batch mode
    scratchpad_input = 'Batch'
    # Set the input before the run
    find_by_id('__papyros-switch-input-mode').click
    # input area should be re-rendered
    codemirror_send_keys(find_by_id('scratchpad-input-wrapper'), "#{scratchpad_input}\n")
    run_code ''

    output_area.find('span', text: scratchpad_input)

    # Scratchpad can sleep and be interrupted
    code = "import time\nprint(\"Start\")\ntime.sleep(3)\nprint(\"Stop\")\n"
    run_code code

    output_area.find('span', text: 'Start')
    output_area.find('span', text: 'Stop')
    run_code ''
    sleep(1)
    find_button('__papyros-stop-btn', disabled: false).click

    output_area.find('span', text: 'Start')
    assert output_area.has_no_xpath?('.//span', text: 'Stop')
  end
end
