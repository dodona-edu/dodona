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
    @submission = create :correct_submission, result: Rails.root.join('db/results/python-result.json').read, code: @code_lines.join("\n"), course: @course
    @submission.exercise.judge.renderer = PythiaRenderer
    @submission.exercise.judge.save
    @student = @submission.user
    sign_in @student

    @orig = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = true
  end

  teardown do
    Delayed::Worker.delay_jobs = @orig
  end

  test 'Can ask question for each line of the available lines of code' do
    visit(submission_path(id: @submission.id))
    click_on 'Code'

    within '.code-listing' do
      (1..@code_lines.length).each do |index|
        line = "tr#line-#{index}"
        line_element = find(line)
        line_element.hover

        within line_element do
          button = find('.annotation-button a')
          button.click

          assert_css 'form.annotation-submission'
          # cancel form to limit page space taken
          within 'form.annotation-submission' do
            click_on 'Cancel'
          end
        end
      end
    end
  end

  test 'Can ask global question about code' do
    visit(submission_path(id: @submission.id))
    click_on 'Code'

    within '.code-table' do
      click_on 'Ask a question about your code'

      assert_css 'form.annotation-submission'
    end
  end

  test 'Can submit a question' do
    visit(submission_path(id: @submission.id))
    click_on 'Code'

    question = Faker::Lorem.question

    within '.code-table' do
      click_on 'Ask a question about your code'

      form = find('form.annotation-submission')

      within form do
        text_area = find('textarea')
        text_area.fill_in with: question
      end

      click_on 'Ask question'

      assert_text question
      # Also acts as sleep until full ajax call is completed
    end

    assert_equal 1, Question.count, 'Too little or too many questions were created'
    q = Question.first

    assert_equal q.question_text, question, 'Something went wrong in saving the question'
    assert_predicate q, :unanswered?, 'Should be an unanswered question'
  end

  test 'student can mark a question as resolved' do
    q = create :question, submission: @submission, user: @student

    assert_equal 1, Question.count, 'Test is invalid if magically no or more questions appear here'
    assert_predicate q, :unanswered?, 'Question should start as unanswered'

    visit(submission_path(id: @submission.id))
    click_on 'Code'

    thread = find('d-thread')
    within thread do
      resolve_button = find('.btn', text: 'Mark as answered')
      resolve_button.click

      assert_no_css '.mdi-comment-question-outline'
    end

    assert_equal 1, Question.count, 'There should still only be one question'
    q = Question.first

    assert_not q.unanswered?, 'Question should have moved onto answered status'
    assert_predicate q, :answered?, 'Question should have moved onto answered status'
  end

  test 'Responding to a question should mark the question as answered' do
    q = create :question, submission: @submission, user: @student

    assert_equal 1, Question.count, 'Test is invalid if magically no or more questions appear here'
    assert_predicate q, :unanswered?, 'Question should start as unanswered'

    visit(submission_path(id: @submission.id))
    click_on 'Code'

    thread = find('d-thread')
    within thread do
      assert_selector '.annotation', count: 1

      fake_answer_input = find('input')
      fake_answer_input.click

      answer = Faker::Lorem.sentence
      answer_field = find('textarea')
      answer_field.fill_in with: answer

      click_on 'Reply'

      assert_selector '.annotation', count: 2
    end

    assert_equal 2, Question.count, 'There should be two questions now'
    assert_not q.reload.unanswered?, 'Question should have moved onto answered status'
    assert_predicate q.reload, :answered?, 'Question should have moved onto answered status'
  end

  test 'An unanswered question should contain an icon to visualize its status' do
    q = create :question, submission: @submission, user: @student

    assert_equal 1, Question.count, 'Test is invalid if magically no or more questions appear here'
    assert_predicate q, :unanswered?, 'Question should start as unanswered'

    visit(submission_path(id: @submission.id))
    click_on 'Code'

    thread = find('d-thread')

    within thread do
      assert_selector '.mdi-comment-question-outline'
    end
  end

  test 'The status icon should change to in progress when someone clicks reply' do
    q = create :question, submission: @submission, user: @student

    assert_equal 1, Question.count, 'Test is invalid if magically no or more questions appear here'
    assert_predicate q, :unanswered?, 'Question should start as unanswered'

    visit(submission_path(id: @submission.id))
    click_on 'Code'

    thread = find('d-thread')
    within thread do
      assert_selector '.mdi-comment-question-outline'
      fake_answer_input = find('input')
      fake_answer_input.click

      assert_selector '.mdi-comment-processing-outline'
      assert_predicate q.reload, :in_progress?, 'Question should have moved onto in progress status'
    end
  end

  test 'The question becomes unanswered again when a teacher cancels the reply' do
    q = create :question, submission: @submission, user: @student

    assert_equal 1, Question.count, 'Test is invalid if magically no or more questions appear here'
    assert_predicate q, :unanswered?, 'Question should start as unanswered'

    visit(submission_path(id: @submission.id))
    click_on 'Code'

    thread = find('d-thread')
    within thread do
      assert_selector '.mdi-comment-question-outline'
      fake_answer_input = find('input')
      fake_answer_input.click

      assert_selector '.mdi-comment-processing-outline'
      assert_predicate q.reload, :in_progress?, 'Question should have moved onto in progress status'

      click_on 'Cancel'

      assert_selector '.mdi-comment-question-outline'
      assert_predicate q.reload, :unanswered?, 'Question should have moved onto unanswered status'
    end
  end
end
