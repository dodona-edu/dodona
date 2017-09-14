# summary for a group of exercises, optionally within a given Series.
# powers the 'exercises_table' view partial.
class ExercisesSummary
  attr_reader :series,
              :user,
              :exercises

  include Enumerable

  def initialize(**kwargs)
    @user = kwargs[:user]
    @series = kwargs[:series]
    @exercises = kwargs[:exercises]&.to_a

    if series
      @series_memberships =
        if exercises
          series.series_memberships.where(exercise: exercises)
        else
          series.series_memberships.includes(:exercise)
        end
      @exercises ||= @series_memberships.map(&:exercise)
    end

    @latest_submissions = kwargs[:latest_submissions] ||
                          query_latest_submissions
    @accepted_submissions = kwargs[:accepted_submissions] ||
                            query_accepted_submissions
    @timely_submissions = kwargs[:timely_submissions] ||
                          query_timely_submissions
  end

  def each(&block)
    exercise_summaries.each(&block)
  end

  def exercise_summaries
    if series
      @series_memberships.map do |membership|
        mk_exercise_summary membership.exercise, series_membership: membership
      end
    else
      @exercises.map do |ex|
        mk_exercise_summary ex
      end
    end
  end

  def number_solved
    count(&:solved_before_deadline?)
  end

  def progress
    number_solved.to_f / count
  end

  private

  def mk_exercise_summary(ex, **kwargs)
    ExerciseSummary.new(
      exercise: ex,
      user: user,
      latest_submission: @latest_submissions[ex.id],
      accepted_submission: @accepted_submissions[ex.id],
      timely_submission: @timely_submissions[ex.id],
      **kwargs
    )
  end

  def query_submissions
    s = Submission.where(user: user, exercise: exercises)
    s = s.where(course_id: series.course_id) if series
    s
  end

  def query_latest_submissions
    return {} unless user
    query_submissions.exercise_hash
  end

  def query_accepted_submissions
    return {} unless user
    query_submissions.where(accepted: true).exercise_hash
  end

  def query_timely_submissions
    return {} unless user
    return @latest_submissions unless series&.deadline
    query_submissions.before_deadline(series.deadline).exercise_hash
  end
end
