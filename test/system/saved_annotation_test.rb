require 'capybara/minitest'
require 'application_system_test_case'

class SavedAnnotationsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  setup do
    @zeus = create :zeus
    @staff = create :staff
    @student = create :student
    @course = create :course, id: 10
    CourseMembership.create user: @staff, status: :course_admin, course: @course

    @instances = []
    3.times do
      code_lines = Faker::Lorem.sentences(number: 5)
      instance = create :correct_submission, result: Rails.root.join('db/results/python-result.json').read, code: code_lines.join("\n"), course: @course, user: @student
      instance.exercise.judge.renderer = PythiaRenderer
      instance.exercise.judge.save
      @instances << instance
    end
    @first = @instances.first
  end

  test 'Staff can save an annotation' do
    sign_in @staff
    visit(submission_path(id: @first.id))
    click_link 'Code'

    find('tr#line-1').hover
    find('.annotation-button button').click

    initial = 'The first five words of this comment will be used as the title'
    within 'form.annotation-submission' do
      assert_no_css 'd-saved-annotation-input'

      find('textarea.annotation-submission-input').fill_in with: initial

      # assert checkbox to fill out title
      assert_css '#check-save-annotation'
      assert_no_css '#saved-annotation-title'
      find('#check-save-annotation').check
      assert_equal 'The first five words of', find('#saved-annotation-title').value
      click_button 'Comment'
    end

    within '.annotation' do
      assert_text initial
      # assert linked icon
      assert_css 'i.mdi-comment-bookmark-outline'
    end
    sign_out @staff
  end

  test 'Student cannot save an annotation' do
    sign_in @student
    visit(submission_path(id: @first.id))
    click_link 'Code'

    find('tr#line-1').hover
    find('.annotation-button button').click

    initial = 'The first five words of this comment will be used as the title'
    within 'form.annotation-submission' do
      assert_no_css 'd-saved-annotation-input'
      find('textarea.annotation-submission-input').fill_in with: initial
      assert_no_css '#check-save-annotation'
      click_button 'Ask question'
    end

    within '.annotation' do
      assert_text initial
      assert_no_css 'i.mdi-link-variant'
    end

    sign_out @student
  end

  test 'Staff can reuse an annotation' do
    sign_in @staff
    sa = create :saved_annotation, user: @staff, exercise: @first.exercise, course: @course
    visit(submission_path(id: @first.id))

    click_link 'Code'

    find('tr#line-1').hover
    find('.annotation-button button').click

    within 'form.annotation-submission' do
      assert_css 'd-saved-annotation-input'

      find('d-saved-annotation-input input[type="text"]').fill_in with: sa.title
      assert find_field('Comment', with: sa.annotation_text)
      assert_equal sa.annotation_text, find('textarea.annotation-submission-input').value

      click_button 'Comment'
    end

    within '.annotation' do
      assert_text sa.annotation_text
      # assert linked icon
      assert_css 'i.mdi-comment-bookmark-outline'
    end
    sign_out @staff
  end
end
