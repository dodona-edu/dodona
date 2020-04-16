module SeriesHelper
  def breadcrumb_series_path(series, user)
    if series.hidden? && !user&.course_admin?(series.course)
      series_path(series, token: series.access_token)
    else
      course_path(series.course, anchor: series.anchor)
    end
  end

  def series_status_deadline_icon(series, user)
    return nil unless series.deadline?
    return 'mdi-alarm-off' if series.missed_deadline?(user)
    return 'mdi-alarm-check' if series.completed_before_deadline?(user: user) && !series.completed?(user)

    nil
  end
end
