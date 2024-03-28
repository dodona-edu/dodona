module SeriesHelper
  def breadcrumb_series_path(series, user)
    if series.hidden? && !user&.course_admin?(series.course)
      series_path(series, token: series.access_token)
    else
      course_path(series.course, anchor: series.anchor)
    end
  end

  # returns [class, icon]
  def series_status_progress(series, user)
    return 'not-yet-begun' unless series.started?(user: user)
    return 'completed' if series.completed?(user: user)
    return 'wrong' if series.wrong?(user: user)

    'started'
  end

  # returns [class, icon]
  def series_status_deadline(series, user)
    return nil unless series.deadline?
    return 'missed' if series.missed_deadline?(user)
    return 'met' if series.completed_before_deadline?(user) && !series.completed?(user: user)

    nil
  end

  def series_status(series, user)
    if series.deadline?
      if series.missed_deadline?(user)
        return t('series.series_status.completed_after_deadline_missed') if series.completed?(user: user)
        return t('series.series_status.wrong_after_deadline_missed')     if series.wrong?(user: user)
        return t('series.series_status.started_after_deadline_missed')   if series.started?(user: user)

        return t('series.series_status.unstarted_after_deadline_missed')
      elsif series.deadline.future?
        return t('series.series_status.completed_before_deadline') if series.completed?(user: user)
        return t('series.series_status.wrong_before_deadline')     if series.wrong?(user: user)
        return t('series.series_status.started_before_deadline')   if series.started?(user: user)

        return t('series.series_status.unstarted_before_deadline')
      end
      return t('series.series_status.completed_after_deadline_met') if series.completed?(user: user)

      return t('series.series_status.wrong_after_deadline_met')
    end

    return t('series.series_status.completed_no_deadline') if series.completed?(user: user)
    return t('series.series_status.wrong_no_deadline')     if series.wrong?(user: user)
    return t('series.series_status.started_no_deadline')   if series.started?(user: user)

    t('series.series_status.unstarted_no_deadline')
  end
end
