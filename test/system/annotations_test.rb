require 'capybara/minitest'
require 'application_system_test_case'

class AnnotationsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  setup do
    @zeus = create(:zeus)
    sign_in @zeus
    @code_lines = Faker::Lorem.sentences(number: 5)
    @instance = create :correct_submission, result: File.read(Rails.root.join('db/results/python-result.json')), code: @code_lines.join("\n"), course: create(:course)
    @instance.exercise.judge.renderer = PythiaRenderer
    @instance.exercise.judge.save
  end

  test 'Can view submission page' do
    visit(submission_path(id: @instance.id))
    within '.card-title' do
      assert_text 'Submission results'
    end
    within '.status-line' do
      assert_text 'Correct'
    end
    within '.card-tab .nav.nav-tabs' do
      assert_text 'Correctheid'
      assert_text 'Code'
    end
    within '.submission-summary .description' do
      assert_text @instance.user.full_name
    end
  end

  test 'Navigate to code tab' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'
    within '.code-listing' do
      @code_lines.each { |code_line| assert_text code_line }
    end
  end

  test 'Submission annotation button is present for each code line' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    within '.code-listing' do
      (1..@code_lines.length).each do |index|
        line = "tr#line-#{index}"
        find(line).hover
        assert_css 'button.annotation-button'
      end
    end
  end

  test 'Click on submission annotation button' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    find('tr#line-1').hover
    find('button.annotation-button').click
    within '.code-listing' do
      @code_lines.each do |code_line|
        assert_text code_line
      end
    end
    assert_no_css '.annotation'
  end

  test 'Enter annotation and send' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    find('tr#line-1').hover
    find('button.annotation-button').click

    initial = 'This is a single line comment'
    within 'form.annotation-submission' do
      find('textarea.annotation-submission-input').fill_in with: initial
      click_button 'Comment'
    end

    within '.annotation' do
      assert_text initial
    end

    assert_no_css 'form.annotation-submission'
  end

  test 'Cancel annotation form' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    find('tr#line-1').hover
    find('button.annotation-button').click
    within 'form.annotation-submission' do
      click_button 'Cancel'
    end

    assert_no_css '.annotation'
    assert_no_css 'form.annotation-submission'
  end

  test 'Edit annotation' do
    annot = create :annotation, submission: @instance, user: @zeus

    visit(submission_path(id: @instance.id))
    click_link 'Code'
    within '.annotation' do
      assert_text annot.annotation_text
    end
    assert_selector('.annotation', count: 1)

    find('.annotation .annotation-control-button.annotation-edit i.mdi.mdi-pencil').click
    replacement = Faker::Lorem.paragraph(sentence_count: 3)

    within 'form.annotation-submission' do
      find('textarea.annotation-submission-input').fill_in with: replacement
      click_button 'Update'
    end

    within '.annotation' do
      assert_text replacement
    end
    assert_selector('.annotation', count: 1)
  end

  test 'Destroy annotation' do
    annot = create :annotation, submission: @instance, user: @zeus

    visit(submission_path(id: @instance.id))
    click_link 'Code'

    within '.annotation' do
      assert_text annot.annotation_text
    end
    assert_selector '.annotation', count: 1

    find('.annotation .annotation-control-button.annotation-edit i.mdi.mdi-pencil').click

    within 'form.annotation-submission' do
      click_button 'Delete'
      accept_confirm('Are you sure you want to delete this comment?')
    end

    assert_no_css '.annotation'
  end

  test 'User moving back and forth over code and tests' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    click_link 'Correctheid'
    click_link 'Code'

    annot = create :annotation, submission: @instance, user: @zeus
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    assert_selector '.annotation', count: 1
    within '.annotation' do
      assert_text annot.annotation_text
    end

    click_link 'Correctheid'
    click_link 'Code'

    assert_selector '.annotation', count: 1
    within '.annotation' do
      assert_text annot.annotation_text
    end
  end

  test 'Edit valid annotation -- Too large input text' do
    annot = create :annotation, submission: @instance, user: @zeus
    visit(submission_path(id: @instance.id))
    click_link 'Code'
    assert_selector '.annotation', count: 1
    within '.annotation' do
      assert_text annot.annotation_text
    end

    find('.annotation .annotation-control-button.annotation-edit i.mdi.mdi-pencil').click
    replacement = Faker::Lorem.characters number: 10_010
    assert_selector 'form.annotation-submission', count: 1
    # Attempt to type more than 10.000 characters.
    within 'form.annotation-submission' do
      input_field = find('textarea.annotation-submission-input')
      # Attempt to fill in with more characters than allowed.
      input_field.fill_in with: replacement
      # The client-side restrictions should have stopped it.
      assert_equal 10_000, input_field.value.length
    end
  end

  test 'Edit valid annotation -- Zero length input text' do
    annot = create :annotation, submission: @instance, user: @zeus
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    assert_selector '.annotation', count: 1
    within '.annotation' do
      assert_text annot.annotation_text
    end

    find('.annotation .annotation-control-button.annotation-edit i.mdi.mdi-pencil').click
    replacement = ''
    within 'form.annotation-submission' do
      find('textarea.annotation-submission-input').fill_in with: replacement
      click_button 'Update'
    end

    # Cancel the form
    within 'form.annotation-submission' do
      click_button 'Cancel'
    end

    # Check if the view is correct without reloading
    assert_selector '.annotation', count: 1
    within '.annotation' do
      assert_text annot.annotation_text
    end

    # After reload, make sure no replacing has taken place
    visit(submission_path(id: @instance.id))
    click_link 'Code'
    assert_selector '.annotation', count: 1
    within '.annotation' do
      assert_text annot.annotation_text
    end

    # Can't check for NOT having empty string since the empty string is a part of any string
  end

  test 'Enter invalid annotation and send - No content' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    find('tr#line-1').hover
    find('button.annotation-button').click

    initial = ''
    within 'form.annotation-submission' do
      find('textarea.annotation-submission-input').fill_in with: initial
      click_button 'Comment'

      # Assuming the update did not go trough
      # If the creation went trough, the cancel button would not exist anymore

      click_button 'Cancel'
    end
    assert_selector '.annotation', count: 0

    # After reload, make sure no creation has taken place
    visit(submission_path(id: @instance.id))
    click_link 'Code'
    assert_selector '.annotation', count: 0
  end

  test 'Enter invalid annotation and send - Content too long' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    find('tr#line-1').hover
    find('button.annotation-button').click

    initial = Faker::Lorem.characters(number: 10_010)
    within 'form.annotation-submission' do
      input = find('textarea.annotation-submission-input')

      # Attempt to write too much input
      input.fill_in with: initial
      # Client should stop it
      assert_equal 10_000, input.value.length
    end
  end

  test 'Enter global annotation' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    click_button 'Add global comment'

    initial = Faker::Lorem.words(number: 128).join(' ')
    within '#feedback-table-global-annotations' do
      find('textarea.annotation-submission-input').fill_in with: initial
      click_button 'Comment'
    end

    assert_selector '.annotation', count: 1
    within '.annotation' do
      assert_text initial
    end
    assert_no_css 'form.annotation-submission'

    # After reload, make sure creation has taken place
    visit(submission_path(id: @instance.id))
    click_link 'Code'
    assert_selector '.annotation', count: 1
    within '.annotation' do
      assert_text initial
    end
    assert_no_css 'form.annotation-submission'
  end

  test 'Edit global annotation' do
    annot = create :annotation, submission: @instance, user: @zeus, line_nr: nil
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    assert_selector '.annotation', count: 1
    within '.annotation' do
      assert_text annot.annotation_text
    end
    old_text = annot.annotation_text

    find('.annotation .annotation-control-button.annotation-edit i.mdi.mdi-pencil').click
    replacement = Faker::Lorem.words(number: 32).join(' ')
    within 'form.annotation-submission' do
      find('textarea.annotation-submission-input').fill_in with: replacement
      click_button 'Update'
    end
    within '.annotation' do
      assert_no_text old_text
      assert_text replacement
    end

    # After reload, make sure creation has taken place
    visit(submission_path(id: @instance.id))
    click_link 'Code'
    assert_selector '.annotation', count: 1
    within '.annotation' do
      assert_text replacement
    end
    assert_no_css 'form.annotation-submission'
  end
end
