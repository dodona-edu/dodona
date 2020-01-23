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
    @instance = create :correct_submission, result: File.read(Rails.root.join('db', 'results', 'python-result.json'))
  end

  test 'Can view submission page' do
    visit(submission_path(id: @instance.id))
    assert page.has_content? 'Correct'
    assert page.has_content? @instance.user.full_name
  end

  test 'Navigate to code tab' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'
    assert page.has_content?(@instance.code)
  end

  test 'Click on submission annotation button' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    find('tr#line-1').hover
    find('button.annotation-button').click
    assert page.has_content?(@instance.code)
  end

  test 'Enter annotation and send' do
    visit(submission_path(id: @instance.id))
    click_link 'Code'

    find('tr#line-1').hover
    find('button.annotation-button').click

    within(:css, 'form.annotation-submission') do
      find('textarea#submission-textarea').fill_in with: 'This is a single line comment'
      click_button 'Send'
    end
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
  end

  test 'Edit annotation' do
    create :annotation, submission: @instance, user: @zeus

    visit(submission_path(id: @instance.id))
    click_link 'Code'

    find('.annotation .annotation-control-button.annotation-edit i.mdi.mdi-pencil').click

    within(:css, 'form.annotation-submission.annotation-edit') do
      find('textarea#submission-textarea').fill_in with: 'This is a different single line comment'
      click_button 'Send'
    end

    assert_text 'This is a different single line comment'
    assert_not all('.annotation').empty?
  end

  test 'Destroy annotation' do
    create :annotation, submission: @instance, user: @zeus

    visit(submission_path(id: @instance.id))
    click_link 'Code'

    find('.annotation .annotation-control-button.annotation-edit i.mdi.mdi-pencil').click

    within(:css, 'form.annotation-submission.annotation-edit') do
      click_button 'Delete'
      accept_confirm('Ben je zeker dat je dit wilt verwijderen?')
    end

    assert has_no_css?('.annotation')
  end
end
