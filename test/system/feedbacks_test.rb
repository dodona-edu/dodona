require 'capybara/minitest'
require 'application_system_test_case'

class FeedbacksTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  setup do
    result = File.read(Rails.root.join('db/results/python-result.json'))
    code_lines = Faker::Lorem.sentences(number: 5)
    @staff_member = create :staff
    series = create :series, exercise_count: 2
    series.course.administrating_members << @staff_member
    @users = [create(:user), create(:user)]
    @exercises = series.exercises
    @users.each do |u|
      series.course.enrolled_members << u
      @exercises.each do |e|
        submission = create :correct_submission, user: u, exercise: e,
                                                 course: series.course,
                                                 created_at: Time.current - 1.hour,
                                                 code: code_lines.join("\n"),
                                                 result: result
        submission.exercise.judge.renderer = PythiaRenderer
        submission.exercise.judge.save
      end
    end
    @evaluation = create :evaluation, series: series, users: @users, exercises: @exercises

    exercise = @evaluation.evaluation_exercises.first
    @rubric_first = create :rubric, evaluation_exercise: exercise,
                                    description: 'Before test',
                                    maximum: '10.0',
                                    scores: []
    @rubric_second = create :rubric, evaluation_exercise: exercise,
                                     description: 'Before test',
                                     maximum: '20.0',
                                     scores: []
    @feedback = @evaluation.feedbacks.first
    @feedback.update!(completed: false)
    @score = create :score, rubric: @rubric_first, feedback: @feedback
    sign_in @staff_member
  end

  test 'can fill in scores for each rubric' do
    visit(feedback_path(id: @feedback.id))

    # The "complete" button should be disabled
    assert_button(class: 'complete-feedback', disabled: true)

    first_input = find(id: "#{@rubric_first.id}-score-form-wrapper").find('.score-input')
    second_input = find(id: "#{@rubric_second.id}-score-form-wrapper").find('.score-input')

    # Check that we can modify existing scores
    first_input.fill_in with: '9.0'
    second_input.click
    # :enabled makes capybara wait on the refresh
    first_input = find(id: "#{@rubric_first.id}-score-form-wrapper").find('.score-input:enabled')
    second_input = find(id: "#{@rubric_second.id}-score-form-wrapper").find('.score-input:enabled')

    @score.reload
    assert_equal BigDecimal('9.0'), @score.score
    assert_button(class: 'complete-feedback', disabled: true)

    # Add new score for second rubric
    second_input.fill_in with: '10.0'
    first_input.click
    find(id: "#{@rubric_second.id}-score-form-wrapper").find('.score-input:enabled')

    @rubric_second.scores.reload
    second_score = @rubric_second.scores.first

    assert_equal BigDecimal('10.0'), second_score.score
    assert_button(class: 'complete-feedback', disabled: false)
  end

  test 'concurrent modifications are shown' do
    visit(feedback_path(id: @feedback.id))

    # Modify the score, e.g. by someone else on another page.
    @score.update(score: BigDecimal('2.0'))

    first_input = find(id: "#{@rubric_first.id}-score-form-wrapper").find('.score-input')
    second_input = find(id: "#{@rubric_second.id}-score-form-wrapper").find('.score-input')

    # Attempt to modify on the page.
    first_input.fill_in with: '-9.0'
    second_input.click

    # :enabled makes capybara wait on the refresh
    first_input = find(id: "#{@rubric_first.id}-score-form-wrapper").find('.score-input:enabled')
    parent = find(id: "#{@rubric_first.id}-score-form-wrapper").find('.form-group.input')

    assert_equal '2', first_input.value
    assert_includes parent[:class], 'has-warning'
  end

  test 'invalid value is allowed but show as error' do
    visit(feedback_path(id: @feedback.id))

    first_input = find(id: "#{@rubric_first.id}-score-form-wrapper").find('.score-input')
    second_input = find(id: "#{@rubric_second.id}-score-form-wrapper").find('.score-input')

    # Attempt to modify on the page.
    first_input.fill_in with: '-9.0'
    second_input.click

    # :enabled makes capybara wait on the refresh
    first_input = find(id: "#{@rubric_first.id}-score-form-wrapper").find('.score-input:enabled')
    parent = find(id: "#{@rubric_first.id}-score-form-wrapper").find('.form-group.input')

    assert_equal '-9', first_input.value
    assert_includes parent[:class], 'has-error'
  end

  test 'all zero works' do
    visit(feedback_path(id: @feedback.id))

    assert_button(class: 'complete-feedback', disabled: true)
    click_button(id: 'zero-button')

    # :enabled makes capybara wait on the refresh
    first_input = find(id: "#{@rubric_first.id}-score-form-wrapper").find('.score-input:enabled')
    second_input = find(id: "#{@rubric_second.id}-score-form-wrapper").find('.score-input:enabled')

    assert_equal '0', first_input.value
    assert_equal '0', second_input.value

    assert_button(class: 'complete-feedback', disabled: false)
  end

  test 'all max works' do
    visit(feedback_path(id: @feedback.id))

    assert_button(class: 'complete-feedback', disabled: true)
    click_button(id: 'max-button')

    # :enabled makes capybara wait on the refresh
    first_input = find(id: "#{@rubric_first.id}-score-form-wrapper").find('.score-input:enabled')
    second_input = find(id: "#{@rubric_second.id}-score-form-wrapper").find('.score-input:enabled')

    assert_equal @rubric_first.maximum, BigDecimal(first_input.value)
    assert_equal @rubric_second.maximum, BigDecimal(second_input.value)

    assert_button(class: 'complete-feedback', disabled: false)
  end

  test 'one max works' do
    visit(feedback_path(id: @feedback.id))

    expected_first = @score.score
    assert_button(class: 'complete-feedback', disabled: true)

    score_button = find(id: "#{@rubric_second.id}-score-form-wrapper").find('.score-click')
    score_button.click

    # :enabled makes capybara wait on the refresh
    first_input = find(id: "#{@rubric_first.id}-score-form-wrapper").find('.score-input:enabled')
    second_input = find(id: "#{@rubric_second.id}-score-form-wrapper").find('.score-input:enabled')

    assert_equal expected_first, BigDecimal(first_input.value)
    assert_equal @rubric_second.maximum, BigDecimal(second_input.value)

    assert_button(class: 'complete-feedback', disabled: false)
  end
end
