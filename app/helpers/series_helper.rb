module SeriesHelper
  def breadcrumb_series_path(series, user)
    if series.hidden? && !user&.course_admin?(series.course)
      series_path(series, token: series.access_token)
    else
      course_path(series.course, anchor: series.anchor)
    end
  end

  def deadline_class(met, future)
    return 'deadline-ok' if met
    return 'deadline-future' if future

    'deadline-passed'
  end

  def deadline_icon(met, future)
    return 'mdi-alarm-check' if met
    return 'mdi-alarm' if future

    'mdi-alarm-off'
  end
end
