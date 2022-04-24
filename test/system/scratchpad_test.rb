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

    # Open Papyros ready for use
    visit(course_activity_path(course_id: @course.id, id: @exercise.id))
    assert_selector '#scratchpad-offcanvas-show-btn'
    find('#scratchpad-offcanvas-show-btn').click
  end

  # Set code in the editor and run it
  def run_code(code)
    assert_selector '.cm-editor'
    # Focus editor
    find('.cm-editor').click
    find('.cm-content').send_keys code
    find('#__papyros-run-code-btn').click
  end

  test 'Scratchpad can run code' do
    it 'Can run Hello World!' do
      run_code 'print("Hello World!")'

      output_area = find('#scratchpad-output-wrapper', wait: 20)
      output_area.find('span', text: 'Hello World!')
    end
  end
end
