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
end
