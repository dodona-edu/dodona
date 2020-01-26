require 'capybara/minitest'
require 'system/generic_system_test'

class AnnotationsTest < GenericSystemTest
  include Devise::Test::IntegrationHelpers
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  setup do
    @zeus = create(:zeus)
    sign_in @zeus
    @code_lines = Faker::Lorem.sentences(number: 5)
    @instance = create :correct_submission, result: File.read(Rails.root.join('db', 'results', 'python-result.json')), code: @code_lines.join("\n")
  end

  test 'Can view submission page' do
    visit(submission_path(id: @instance.id))
    assert_text 'Correct'
    assert_text 'Correctheid'
    assert_text @instance.user.full_name
  end

  test 'Navigate to code tab' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'
    @code_lines.each { |code_line| assert_text code_line }
  end

  test 'Submission annotation button is present for each code line' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    (1..@code_lines.length).each { |index|
      line = "tr#line-#{index}"
      find(line).hover
      assert_css "#{line} button.annotation-button"
    }
  end

  test 'Click on submission annotation button' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    find('tr#line-1').hover
    find('button.annotation-button').click
    @code_lines.each { |code_line|
      assert_text code_line
    }
    assert_no_css '.annotation'
  end

  test 'Enter annotation and send' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    find('tr#line-1').hover
    find('button.annotation-button').click

    initial = 'This is a single line comment'
    within(:css, 'form.annotation-submission') do
      find('textarea#submission-textarea').fill_in with: initial
      click_button 'Send'
    end

    assert_text initial
    assert_no_css 'form.annotation-submission'
  end

  test 'Cancel annotation form' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    find('tr#line-1').hover
    find('button.annotation-button').click
    within(:css, 'form.annotation-submission') do
      click_button 'Cancel'
    end

    assert all('.annotation').empty?
    assert_no_css 'form.annotation-submission'
  end

  test 'Edit annotation' do
    annot = create :annotation, submission: @instance, user: @zeus

    visit(submission_path(id: @instance.id))
    click_link 'Code'
    assert_text annot.annotation_text

    find('.annotation .annotation-control-button.annotation-edit i.mdi.mdi-pencil').click

    within(:css, 'form.annotation-submission.annotation-edit') do
      find('textarea#submission-textarea').fill_in with: 'This is a different single line comment'
      click_button 'Send'
    end

    assert_text 'This is a different single line comment'
    assert_css '.annotation'
  end

  test 'Destroy annotation' do
    annot = create :annotation, submission: @instance, user: @zeus

    visit(submission_path(id: @instance.id))
    click_link 'Code'

    assert_text annot.annotation_text
    find('.annotation .annotation-control-button.annotation-edit i.mdi.mdi-pencil').click

    within(:css, 'form.annotation-submission.annotation-edit') do
      click_button 'Delete'
      accept_confirm('Ben je zeker dat je dit wilt verwijderen?')
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
    assert_text annot.annotation_text
    click_link 'Correctheid'
    click_link 'Code'
    assert_text annot.annotation_text
  end

  test 'Edit valid annotation -- Too large input text' do
    annot = create :annotation, submission: @instance, user: @zeus
    visit(submission_path(id: @instance.id))
    click_link 'Code'
    assert_text annot.annotation_text

    find('.annotation .annotation-control-button.annotation-edit i.mdi.mdi-pencil').click
    replacement = (Faker::Lorem.words number: 512).join(' ')
    within(:css, 'form.annotation-submission.annotation-edit') do
      find('textarea#submission-textarea').fill_in with: replacement
      click_button 'Send'
    end

    assert_no_text replacement
  end

  test 'Edit valid annotation -- Zero length input text' do
    annot = create :annotation, submission: @instance, user: @zeus
    visit(submission_path(id: @instance.id))
    click_link 'Code'
    assert_text annot.annotation_text

    find('.annotation .annotation-control-button.annotation-edit i.mdi.mdi-pencil').click
    replacement = ''
    within(:css, 'form.annotation-submission.annotation-edit') do
      find('textarea#submission-textarea').fill_in with: replacement
      click_button 'Send'
    end

    assert_text annot.annotation_text
  end

  test 'Enter invalid annotation and send - No content' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    find('tr#line-1').hover
    find('button.annotation-button').click

    initial = ''
    within(:css, 'form.annotation-submission') do
      find('textarea#submission-textarea').fill_in with: initial
      click_button 'Send'
    end

    assert_css 'form.annotation-submission'
  end

  test 'Enter invalid annotation and send - Content too long' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    find('tr#line-1').hover
    find('button.annotation-button').click

    initial = Faker::Lorem.words(number: 512).join(' ')
    within(:css, 'form.annotation-submission') do
      find('textarea#submission-textarea').fill_in with: initial
      click_button 'Send'
    end

    assert_css 'form.annotation-submission'
    assert_no_text initial
  end
end
