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
    return %w[not-yet-begun mdi-school] unless series.started?(user: user)
    return %w[completed mdi-check-bold] if series.completed?(user: user)
    return %w[wrong mdi-close] if series.wrong?(user: user)

    %w[started mdi-thumb-up]
  end

  # returns [class, icon]
  def series_status_deadline(series, user)
    return [nil, nil] unless series.deadline?
    return %w[deadline-missed mdi-alarm-off] if series.missed_deadline?(user)
    return %w[deadline-met mdi-alarm-check] if series.completed_before_deadline?(user) && !series.completed?(user: user)

    [nil, nil]
  end

  def series_status(series, user)
    if series.deadline?
      if series.missed_deadline?(user)
        if series.completed?(user: user)
          t('series.series_status.completed_after_deadline_missed')
        elsif series.wrong?(user: user)
          t('series.series_status.wrong_after_deadline_missed')
        elsif series.started?(user: user)
          t('series.series_status.started_after_deadline_missed')
        else
          t('series.series_status.unstarted_after_deadline_missed')
        end
      elsif series.deadline.future?
        if series.completed?(user: user)
          t('series.series_status.completed_before_deadline')
        elsif series.wrong?(user: user)
          t('series.series_status.wrong_before_deadline')
        elsif series.started?(user: user)
          t('series.series_status.started_before_deadline')
        else
          t('series.series_status.unstarted_before_deadline')
        end
      elsif series.completed?(user: user)
        t('series.series_status.completed_after_deadline_met')
      else
        t('series.series_status.wrong_after_deadline_met')
      end
    elsif series.completed?(user: user)
      t('series.series_status.completed_no_deadline')
    elsif series.wrong?(user: user)
      t('series.series_status.wrong_no_deadline')
    elsif series.started?(user: user)
      t('series.series_status.started_no_deadline')
    else
      t('series.series_status.unstarted_no_deadline')
    end
  end
end
