require 'capybara/minitest'
require 'application_system_test_case'

class ScoreItemsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  def setup
    @evaluation = create :evaluation, :with_submissions
    @staff_member = create :staff
    @evaluation.series.course.administrating_members << @staff_member
    sign_in @staff_member
    @exercise = @evaluation.evaluation_exercises.first
    @score_item = create :score_item, evaluation_exercise: @exercise,
                                      description: 'Before test',
                                      maximum: '400.0',
                                      visible: false
  end

  test 'updating score item works' do
    visit(edit_evaluation_path(id: @evaluation.id))

    # Ensure we don't accidentally test nothing
    assert_no_text '314.25'

    # Click the edit button of the score item
    find("a[href=\"\#edit-form-#{@score_item.id}\"]").click
    # Change value of score item
    find(id: "#{@exercise.id}_score_item_maximum").fill_in with: '314.25'
    # Save our changes to the score item
    find(id: "#{@exercise.id}_edit_score_item_#{@score_item.id}").find('input[type=submit]').click

    # Check that the score has been updated on the page
    assert_text '314.25'
  end
end
