class ExerciseSummary
  attr_reader :exercise,
              :user,
              :series,
              :series_membership,
              :latest_submission,
              :timely_submission,
              :accepted_submission

  def initialize(**kwargs)
    @series_membership = kwargs[:series_membership]
    @exercise = kwargs[:exercise] || @series_membership&.exercise
    @series = kwargs[:series] || @series_membership&.series
    @series_membership ||= series_memberships.find_by(exercise: exercise) if series

    @user = kwargs[:user]

    @latest_submission = kwargs[:latest_submission] || query_submissions.first
    @timely_submission = kwargs[:timely_submission] || query_timely_submission
    @accepted_submission = kwargs[:accepted_submission] ||
                           query_accepted_submission
  end

  # whether latest submission is correct
  def solved?
    latest_submission&.accepted
  end

  # whether last submission before deadline is correct
  def solved_before_deadline?
    timely_submission&.accepted
  end

  # whether the user has submitted a solution for this exercise
  def submitted?
    latest_submission != nil
  end

  def accepted_submission_exists?
    accepted_submission != nil
  end

  def deadline
    series&.deadline
  end

  def deadline_passed?
    deadline && deadline < Time.current
  end

  def users_correct
    if series_membership
      series_membership.cached_users_correct
    else
      exercise.users_correct
    end
  end

  def users_tried
    if series_membership
      series_membership.cached_users_tried
    else
      exercise.users_tried
    end
  end

  private

  def query_submissions
    s = exercise.submissions.where(user: user).reorder(id: :desc)
    if series
      s.join_series.where(series: { id: series.id } )
    else
      s.where(course: nil)
    end
  end

  def query_timely_submissions
    query_submissions.timely
  end

  def query_accepted_submission
    # no need to query here if no submissions were made
    query_submissions.find_by(accepted: true) if submitted?
  end

  def query_timely_submission
    if deadline
      query_submissions.timely.first
    else
      latest_submission
    end
  end
end
