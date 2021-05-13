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

  def embedded_svg filename, options={}
   file = File.read(Rails.root.join('app', 'assets', 'images', filename))
   doc = Nokogiri::HTML::DocumentFragment.parse file
   svg = doc.at_css 'svg'
   if options[:class].present?
     svg['class'] = options[:class]
   end
   doc.to_html.html_safe
 end
end
