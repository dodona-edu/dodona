module DeadlinesHelper
  def deadline_class(met, deadline)
    return 'deadline-ok' if met
    return 'deadline-future' if deadline.future?

    'deadline-passed'
  end

  def deadline_icon(met, deadline)
    return 'mdi-alarm-check' if met
    return 'mdi-alarm' if deadline.future?

    'mdi-alarm-off'
  end

  def deadline_relative_time(deadline)
    return t('deadlines.relative.in', time_left: time_ago_in_words(deadline)) if deadline.future?

    t('deadlines.relative.ago', time_ago: time_ago_in_words(deadline))
  end
end
