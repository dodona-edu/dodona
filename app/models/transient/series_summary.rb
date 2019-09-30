# summary for a group of exercises, optionally within a given Series.
# powers the 'exercises_table' view partial.
class SeriesSummary
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
          series.series_memberships.where(exercise: exercises).includes(:exercise)
        else
          series.series_memberships.includes(:exercise)
        end
      @exercises ||= @series_memberships.map(&:exercise)
    end

    @latest_submissions = kwargs[:latest_submissions] || query_latest_submissions
    @accepted_submissions = kwargs[:accepted_submissions] || query_accepted_submissions
    @timely_submissions = kwargs[:timely_submissions] || query_timely_submissions
  end

  def progress_status
    if !started?
      'not-yet-begun'
    elsif completed?
      'completed'
    elsif wrong?
      'wrong'
    elsif started?
      'started'
    end
  end

  def deadline_status
    if @series.deadline&.past?
      if all?(&:solved_before_deadline?)
        'deadline-met'
      else
        'deadline-missed'
      end
    else
      ''
    end
  end

  def full_status
    progress_status + ' ' + deadline_status
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

  def number_solved_before_deadline
    count(&:solved_before_deadline?)
  end

  def number_solved
    count(&:solved?)
  end

  def number_wrong
    count(&:wrong?)
  end

  def progress_percentage(step: 1)
    pct = (number_solved * 100) / count
    pct /= step
    pct * step
  end

  def wrong_percentage(step: 1)
    pct = (number_wrong * 100) / count
    pct /= step
    pct * step
  end

  def progress
    number_solved.to_f / count
  end

  def wrong?
    any?(&:wrong?)
  end

  def completed?
    all?(&:solved?)
  end

  def started?
    query_submissions.any?
  end

  def deadline_missed?
    @series.deadline&.past? && !all?(&:solved_before_deadline?)
  end

  def deadline_met?
    @series.deadline&.past? && all?(&:solved_before_deadline?)
  end

  private

  def mk_exercise_summary(exercise, **kwargs)
    ExerciseSummary.new(
      exercise: exercise,
      user: user,
      latest_submission: @latest_submissions[exercise.id],
      accepted_submission: @accepted_submissions[exercise.id],
      timely_submission: @timely_submissions[exercise.id],
      **kwargs
    )
  end

  def query_submissions
    s = Submission.judged.where(user: user, exercise: exercises)
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
