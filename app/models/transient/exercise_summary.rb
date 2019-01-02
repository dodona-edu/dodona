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
    @series_membership ||= series.series_memberships.find_by(exercise: exercise) if series

    @user = kwargs[:user]

    @latest_submission = kwargs.key?(:latest_submission) ? kwargs[:latest_submission] : query_submissions.first
    @timely_submission = kwargs.key?(:timely_submission) ? kwargs[:timely_submission] : query_timely_submission
    @accepted_submission = kwargs.key?(:accepted_submission) ? kwargs[:accepted_submission] : query_accepted_submission
  end

  # whether latest submission is wrong, if it exists
  def wrong?
    latest_submission.present? && !latest_submission.accepted
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

  delegate :deadline, to: :series, allow_nil: true

  def deadline_passed?
    deadline&.past?
  end

  def users_correct
    exercise.users_correct(course: series_membership&.course)
  end

  def users_tried
    exercise.users_tried(course: series_membership&.course)
  end

  private

  def query_submissions
    s = Submission.where(user: user, exercise: exercise).reorder(id: :desc)
    s = s.where(course_id: series.course_id) if series
    s
  end

  def query_accepted_submission
    # no need to query here if no submissions were made
    query_submissions.find_by(accepted: true) if submitted?
  end

  def query_timely_submission
    if deadline
      query_submissions.find_by('submissions.created_at < ?', series.deadline)
    else
      latest_submission
    end
  end
end
