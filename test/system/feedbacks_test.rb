require 'capybara/minitest'
require 'application_system_test_case'

class FeedbacksTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  # Note for all tests: the score input has a delay before the changes are submitted.
  # We use selectors with ":not(.in-progress)" to make capybara wait on the refresh
  # before continuing
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
    @score_item_first = create :score_item, evaluation_exercise: exercise,
                                            description: 'Before test',
                                            maximum: '10.0',
                                            scores: []
    @score_item_second = create :score_item, evaluation_exercise: exercise,
                                             description: 'Before test',
                                             maximum: '20.0',
                                             scores: []
    @feedback = @evaluation.feedbacks.first
    @feedback.update!(completed: false)
    @score = create :score, score_item: @score_item_first, feedback: @feedback
    sign_in @staff_member
  end

  test 'can fill in scores for each score_item' do
    visit(feedback_path(id: @feedback.id))

    first_input = find(id: "#{@score_item_first.id}-score-form-wrapper").find('.score-input')
    second_input = find(id: "#{@score_item_second.id}-score-form-wrapper").find('.score-input')

    # Check that we can modify existing scores
    first_input.fill_in with: '9.0'
    second_input.click

    first_input = find(id: "#{@score_item_first.id}-score-form-wrapper").find('.score-input:not(.in-progress)')
    second_input = find(id: "#{@score_item_second.id}-score-form-wrapper").find('.score-input:not(.in-progress)')

    @score.reload
    assert_equal BigDecimal('9.0'), @score.score

    # Add new score for second score_item
    second_input.fill_in with: '10.0'
    first_input.click

    find(id: "#{@score_item_second.id}-score-form-wrapper").find('.score-input:not(.in-progress)')

    @score_item_second.scores.reload
    second_score = @score_item_second.scores.first

    assert_equal BigDecimal('10.0'), second_score.score
  end

  test 'can save score with enter' do
    visit(feedback_path(id: @feedback.id))

    first_input = find(id: "#{@score_item_first.id}-score-form-wrapper").find('.score-input')

    # Submit score using enter key.
    first_input.fill_in with: '16.0'
    first_input.send_keys :enter

    find(id: "#{@score_item_first.id}-score-form-wrapper").find('.score-input:not(.in-progress)')

    @score.reload
    assert_equal BigDecimal('16'), @score.score
  end

  test 'concurrent modifications are shown' do
    visit(feedback_path(id: @feedback.id))

    # Modify the score, e.g. by someone else on another page.
    @score.update(score: BigDecimal('2.0'))

    first_input = find(id: "#{@score_item_first.id}-score-form-wrapper").find('.score-input')
    second_input = find(id: "#{@score_item_second.id}-score-form-wrapper").find('.score-input')

    # Attempt to modify on the page.
    first_input.fill_in with: '-9.0'
    second_input.click

    first_input = find(id: "#{@score_item_first.id}-score-form-wrapper").find('.score-input:not(.in-progress)')
    parent = find(id: "#{@score_item_first.id}-score-form-wrapper").find('.form-group.input')

    assert_equal '2', first_input.value
    assert_includes parent[:class], 'has-warning'
  end

  test 'invalid value is allowed but show as error' do
    visit(feedback_path(id: @feedback.id))

    first_input = find(id: "#{@score_item_first.id}-score-form-wrapper").find('.score-input')
    second_input = find(id: "#{@score_item_second.id}-score-form-wrapper").find('.score-input')

    # Attempt to modify on the page.
    first_input.fill_in with: '-9.0'
    second_input.click

    first_input = find(id: "#{@score_item_first.id}-score-form-wrapper").find('.score-input:not(.in-progress)')
    parent = find(id: "#{@score_item_first.id}-score-form-wrapper").find('.form-group.input')

    assert_equal '-9', first_input.value
    assert_includes parent[:class], 'has-error'
  end

  test 'all zero works' do
    visit(feedback_path(id: @feedback.id))

    click_button(id: 'zero-button')

    first_input = find(id: "#{@score_item_first.id}-score-form-wrapper").find('.score-input:not(.in-progress)')
    second_input = find(id: "#{@score_item_second.id}-score-form-wrapper").find('.score-input:not(.in-progress)')

    assert_equal '0', first_input.value
    assert_equal '0', second_input.value
  end

  test 'all max works' do
    visit(feedback_path(id: @feedback.id))
    click_button(id: 'max-button')

    first_input = find(id: "#{@score_item_first.id}-score-form-wrapper").find('.score-input:not(.in-progress)')
    second_input = find(id: "#{@score_item_second.id}-score-form-wrapper").find('.score-input:not(.in-progress)')

    assert_equal @score_item_first.maximum, BigDecimal(first_input.value)
    assert_equal @score_item_second.maximum, BigDecimal(second_input.value)
  end

  test 'one max button works' do
    visit(feedback_path(id: @feedback.id))

    expected_first = @score.score

    score_button = find(id: "#{@score_item_second.id}-score-form-wrapper").find('.single-max-button')
    score_button.click

    first_input = find(id: "#{@score_item_first.id}-score-form-wrapper").find('.score-input:not(.in-progress)')
    second_input = find(id: "#{@score_item_second.id}-score-form-wrapper").find('.score-input:not(.in-progress)')

    assert_equal expected_first, BigDecimal(first_input.value)
    assert_equal @score_item_second.maximum, BigDecimal(second_input.value)
  end

  test 'one zero works' do
    visit(feedback_path(id: @feedback.id))

    expected_first = @score.score

    score_button = find(id: "#{@score_item_second.id}-score-form-wrapper").find('.single-zero-button')
    score_button.click

    first_input = find(id: "#{@score_item_first.id}-score-form-wrapper").find('.score-input:not(.in-progress)')
    second_input = find(id: "#{@score_item_second.id}-score-form-wrapper").find('.score-input:not(.in-progress)')

    assert_equal expected_first, BigDecimal(first_input.value)
    assert_equal BigDecimal('0'), BigDecimal(second_input.value)
  end
end
