class SeriesSummaryTest < ActiveSupport::TestCase
  setup do
    @course = create :course
    @series = create :series, course: @course, exercise_count: 5
    @user = create :user, courses: [@course]
  end

  def summary
    SeriesSummary.new(
      user: @user,
      series: @series,
      exercises: @series.exercises
    )
  end
end

class RunningTest < SeriesSummaryTest
  test 'should not have started yet' do
    create :submission, user: @user, course: @course, exercise: @series.exercises.first, status: :running
    assert_not summary.started?
    assert_equal 0, summary.number_wrong
    assert_equal 0, summary.number_solved
  end

  test 'should not change status if there is a previous submission' do
    create :submission, user: @user, course: @course, exercise: @series.exercises.first, status: :correct, accepted: true
    create :submission, user: @user, course: @course, exercise: @series.exercises.first, status: :running
    assert_equal 'started', summary.progress_status
    assert summary.started?
    assert_equal 0, summary.number_wrong
    assert_equal 1, summary.number_solved
  end
end
