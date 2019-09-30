require 'test_helper'

module ExerciseSummaryTests
  class ExerciseSummaryTest < ActiveSupport::TestCase
    setup do
      @course = create :course
      @exercise = create :exercise
      @series = create :series, course: @course, exercises: [@exercise]
      @user = create :user, courses: [@course]
    end

    def summary
      ExerciseSummary.new(
        user: @user,
        series: @series,
        exercise: @exercise
      )
    end

    def submit(*args, **kwargs)
      create :submission,
             *args,
             user: @user,
             exercise: @exercise,
             course: @course,
             **kwargs
    end
  end

  class NoSubmissions < ExerciseSummaryTest
    test 'should not have deadline' do
      assert_not summary.deadline
    end

    test 'deadline should not be passed' do
      assert_not summary.deadline_passed?
    end

    test 'should not have submitted' do
      assert_not summary.submitted?
    end

    test 'should not be solved' do
      assert_not summary.solved?
    end

    test 'should not be solved before deadline' do
      assert_not summary.solved_before_deadline?
    end

    test 'accepted submission should not exist' do
      assert_not summary.accepted_submission_exists?
    end

    test 'should not be tried by anyone' do
      assert_equal 0, summary.users_tried
    end

    test 'should not be completed by anyone' do
      assert_equal 0, summary.users_correct
    end
  end

  class CorrectSubmission < ExerciseSummaryTest
    setup do
      submit :correct
    end

    test 'should have submitted' do
      assert summary.submitted?
    end

    test 'should be solved' do
      assert summary.solved?
    end

    test 'should be solved before deadline' do
      assert summary.solved_before_deadline?
    end

    test 'accepted submission should exist' do
      assert summary.accepted_submission_exists?
    end

    test 'should have been tried' do
      assert_equal 1, summary.users_tried
    end

    test 'should have been completed by someone' do
      assert_equal 1, summary.users_correct
    end
  end

  class IncorrectSubmission < ExerciseSummaryTest
    setup do
      submit :wrong
    end

    test 'should be submitted' do
      assert summary.submitted?
    end

    test 'should not be solved' do
      assert_not summary.solved?
    end

    test 'should not be solved before deadline' do
      assert_not summary.solved_before_deadline?
    end

    test 'accepted submission should not exist' do
      assert_not summary.accepted_submission_exists?
    end

    test 'should have been tried' do
      assert_equal 1, summary.users_tried
    end

    test 'should not have been completed' do
      assert_equal 0, summary.users_correct
    end
  end

  class AcceptedNotLast < ExerciseSummaryTest
    setup do
      submit :correct
      submit :wrong
    end

    test 'should not be solved' do
      assert_not summary.solved?
    end

    test 'should not be solved before deadline' do
      assert_not summary.solved_before_deadline?
    end

    test 'accepted submission should exist' do
      assert summary.accepted_submission_exists?
    end
  end

  class DeadlineAhead < ExerciseSummaryTest
    setup do
      @series.update deadline: 1.day.from_now
      submit :correct
    end

    test 'should have deadline' do
      assert summary.deadline
    end

    test 'deadline should not be passed' do
      assert_not summary.deadline_passed?
    end

    test 'should be solved before deadline' do
      assert summary.solved_before_deadline?
    end
  end

  class DeadlinePassed < ExerciseSummaryTest
    setup do
      @series.update deadline: 1.day.ago
      submit :wrong, created_at: 2.days.ago
      submit :correct
    end

    test 'should have submitted' do
      assert summary.submitted?
    end

    test 'should be solved' do
      assert summary.solved?
    end

    test 'should not be solved before deadline' do
      assert_not summary.solved_before_deadline?
    end

    test 'accepted submission should exist' do
      assert summary.accepted_submission_exists?
    end

    test 'deadline should be passed' do
      assert summary.deadline_passed?
    end
  end

  class SubmittedAtDeadline < ExerciseSummaryTest
    setup do
      t = Time.current
      @series.update deadline: t
      submit :correct, created_at: t
    end

    test 'should not be solved before deadline' do
      assert_not summary.solved_before_deadline?
    end
  end

  class SolvedForOtherCourse < ExerciseSummaryTest
    setup do
      @other_course = create :course
      submit :correct, course: @other_course
    end

    test 'should not be submitted for this course' do
      assert_not summary.submitted?
    end

    test 'should not be solved before deadline for this course' do
      assert_not summary.solved_before_deadline?
    end

    test 'should not have an accepted solution for this course' do
      assert_not summary.accepted_submission_exists?
    end
  end

  class DifferentDeadlines < ExerciseSummaryTest
    setup do
      @series.update deadline: 1.day.from_now
      @other_series = create :series,
                             course: @course,
                             deadline: 1.day.ago,
                             exercises: [@exercise]
      submit :correct
    end

    def other_summary
      ExerciseSummary.new(
        user: @user,
        series: @other_series,
        exercise: @exercise
      )
    end

    test 'should be solved for series' do
      assert summary.solved?
    end

    test 'should be solved for other_series' do
      assert other_summary.solved?
    end

    test 'should be solved before deadline for series' do
      assert summary.solved_before_deadline?
    end

    test 'should not be solved before deadline for other_series' do
      assert_not other_summary.solved_before_deadline?
    end
  end

  class WithoutSeries < ExerciseSummaryTest
    def summary
      ExerciseSummary.new(
        user: @user,
        exercise: @exercise
      )
    end

    setup do
      submit :correct
    end

    test 'should have been submitted' do
      assert summary.submitted?
    end

    test 'should be solved' do
      assert summary.solved?
    end

    test 'should have been tried' do
      assert_equal 1, summary.users_tried
    end

    test 'should have been completed' do
      assert_equal 1, summary.users_correct
    end
  end

  class NotYetJudged < ExerciseSummaryTest
    setup do
      submit status: :running
    end

    test 'should not have been submitted' do
      assert_not summary.submitted?
    end

    test 'should not be solved' do
      assert_not summary.solved?
    end

    test 'should not have been tried' do
      assert_equal 0, summary.users_tried
    end

    test 'should not have been completed' do
      assert_equal 0, summary.users_correct
    end
  end

  class ExercisesSummaryTest < ExerciseSummaryTest
    setup do
      @series.update deadline: Time.current
      # no submission: @exercise

      # correct submission
      ex1 = create :exercise, series: [@series], name: 'ex1'
      submit :correct, exercise: ex1, created_at: 1.day.ago

      # wrong submission
      ex2 = create :exercise, series: [@series], name: 'ex2'
      submit :wrong, exercise: ex2, created_at: 1.day.ago

      # correct after deadline
      ex3 = create :exercise, series: [@series], name: 'ex3'
      submit :correct, exercise: ex3, created_at: 1.day.from_now

      # last not best
      ex4 = create :exercise, series: [@series], name: 'ex4'
      submit :correct, exercise: ex4, created_at: 2.days.ago
      submit :wrong, exercise: ex4, created_at: 1.day.ago

      @series.reload
    end

    # assert that the created summaries are equal to individually created ones
    def assert_summary(summary, exercises: nil, series: nil)
      exercises ||= series.exercises

      assert_equal exercises.count, summary.count
      exercises.each do |exercise|
        expected = ExerciseSummary.new(
          exercise: exercise,
          series: series,
          user: @user
        )

        produced = summary.find { |ex| ex.exercise == exercise }

        assert_not_nil produced

        assert_identical :latest_submission, expected, produced
        assert_identical :timely_submission, expected, produced
        assert_identical :accepted_submission, expected, produced
      end
    end

    def assert_identical(sym, expected, actual)
      if expected.send(sym)
        assert_equal expected.send(sym), actual.send(sym),
                     "#{sym} did not match for #{expected.exercise.name}"
      else
        assert_nil actual.send(sym),
                   "expected #{sym} to be nil for #{expected.exercise.name}"
      end
    end

    test 'should generate correct summary for series' do
      summary = ExercisesSummary.new series: @series,
                                     user: @user
      assert_summary summary, series: @series
    end

    test 'should generate correct summary for exercises' do
      summary = ExercisesSummary.new user: @user,
                                     exercises: @series.exercises
      assert_summary summary, exercises: @series.exercises
    end

    test 'should generate correct summary for subset of exercises' do
      exercises = @series.exercises[1..3]
      summary = ExercisesSummary.new user: @user,
                                     exercises: exercises,
                                     series: @series
      assert_summary summary, exercises: exercises, series: @series
    end
  end
end
