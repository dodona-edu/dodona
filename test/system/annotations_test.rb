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
    @instance = create :correct_submission, result: File.read(Rails.root.join('db/results/python-result.json')), code: @code_lines.join("\n")
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
      click_button 'Annotate'
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
    # assert all('.annotation').empty?
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
      accept_confirm('Are you sure you want to delete this annotation?')
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
    replacement = (Faker::Lorem.words number: 512).join(' ')
    within 'form.annotation-submission' do
      find('textarea.annotation-submission-input').fill_in with: replacement
      click_button 'Update'
    end

    assert_no_text replacement
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

    assert_text annot.annotation_text
  end

  test 'Enter invalid annotation and send - No content' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    find('tr#line-1').hover
    find('button.annotation-button').click

    initial = ''
    within 'form.annotation-submission' do
      find('textarea.annotation-submission-input').fill_in with: initial
      click_button 'Annotate'
    end

    assert_css 'form.annotation-submission'
  end

  test 'Enter invalid annotation and send - Content too long' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    find('tr#line-1').hover
    find('button.annotation-button').click

    initial = Faker::Lorem.words(number: 2048).join(' ')
    within 'form.annotation-submission' do
      find('textarea.annotation-submission-input').fill_in with: initial
      click_button 'Annotate'
    end

    assert_css 'form.annotation-submission'
    assert_no_text initial
  end

  test 'Enter global annotation' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    click_button 'Add global annotation'

    initial = Faker::Lorem.words(number: 128).join(' ')
    within '#feedback-table-global-annotations' do
      find('textarea.annotation-submission-input').fill_in with: initial
      click_button 'Annotate'
    end

    assert_text initial
    assert_no_css 'form.annotation-submission'
  end

  test 'Edit global annotation' do
    annot = create :annotation, submission: @instance, user: @zeus, line_nr: nil
    visit(submission_path(id: @instance.id))
    click_link 'Code'
    assert_text annot.annotation_text
    old_text = annot.annotation_text

    find('.annotation .annotation-control-button.annotation-edit i.mdi.mdi-pencil').click
    replacement = Faker::Lorem.words(number: 128).join(' ')
    within 'form.annotation-submission' do
      find('textarea.annotation-submission-input').fill_in with: replacement
      click_button 'Update'
    end
    assert_no_text old_text
    assert_text replacement
  end
end
