require 'capybara/minitest'
require 'application_system_test_case'

class QuestionsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  setup do
    @code_lines = Faker::Lorem.sentences(number: 5)
    @course = create :course, enabled_questions: true
    @submission = create :correct_submission, result: File.read(Rails.root.join('db/results/python-result.json')), code: @code_lines.join("\n"), course: @course
    @submission.exercise.judge.renderer = PythiaRenderer
    @submission.exercise.judge.save
    @student = @submission.user
    sign_in @student
  end

  test 'Can pose question for each line of the available lines of code' do
    visit(submission_path(id: @submission.id))
    click_link 'Code'

    within '.code-listing' do
      (1..@code_lines.length).each do |index|
        line = "tr#line-#{index}"
        line_element = find(line)
        line_element.hover

        within line_element do
          button = find('button.annotation-button')
          button.click
          assert_css 'form.annotation-submission'
        end
      end
    end
  end

  test 'Can pose global question about code' do
    visit(submission_path(id: @submission.id))
    click_link 'Code'

    within '.code-table' do
      button = find('#add_global_annotation')
      button.click
      assert_css 'form.annotation-submission'
    end
  end

  test 'Can submit a question' do
    visit(submission_path(id: @submission.id))
    click_link 'Code'

    question = Faker::Lorem.question

    within '.code-table' do
      button = find('#add_global_annotation')
      button.click

      form = find('form.annotation-submission')

      within form do
        text_area = find('textarea')
        text_area.fill_in with: question
      end

      click_button 'Send question'

      assert_text question
      # Also acts as sleep until full ajax call is completed
    end

    assert_equal 1, Question.count, 'Too little or too many questions were created'
    q = Question.first
    assert_equal q.question_text, question, 'Something went wrong in saving the question'
    assert q.unanswered?, 'Should be an unanswered question'
  end

  test 'student can mark a question as resolved' do
    q = create :question, submission: @submission, user: @student
    assert_equal 1, Question.count, 'Test is invalid if magically no or more questions appear here'
    assert q.unanswered?, 'Question should start as unanswered'

    visit(submission_path(id: @submission.id))
    click_link 'Code'

    question_div = find('div.annotation.question')
    within question_div do
      resolve_button = find('.question-control-button.question-resolve')
      resolve_button.click
      assert_no_css '.question-control-button.question-resolve'
      # Wait until ajax call is complete
    end

    assert_equal 1, Question.count, 'There should still only be one question'
    q = Question.first
    assert_not q.unanswered?, 'Question should have moved onto answered status'
    assert q.answered?, 'Question should have moved onto answered status'
  end
end
