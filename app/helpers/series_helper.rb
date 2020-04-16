module SeriesHelper
  def breadcrumb_series_path(series, user)
    if series.hidden? && !user&.course_admin?(series.course)
      series_path(series, token: series.access_token)
    else
      course_path(series.course, anchor: series.anchor)
    end
  end

  def series_status_icon(series, user)
    return 'mdi-school' unless series.started?(user)
    return 'mdi-check-bold' if series.completed?(user)
    #<% if !summary.started? %>
    #  <i class="mdi mdi-school"></i>
    #<% elsif summary.completed? %>
    #  <i class="mdi mdi-check-bold"></i>
    #                        <% elsif summary.wrong? %>
    #  <i class="mdi mdi-close"></i>
    #<% elsif summary.started? %>
    #  <i class="mdi mdi-thumb-up"></i>
    #                                                <% end %>
  end

  def series_status_deadline_icon(series, user)
    return nil unless series.deadline?
    return 'mdi-alarm-off' if series.missed_deadline?(user)
    return 'mdi-alarm-check' if series.completed_before_deadline?(user) && !series.completed?(user: user)

    nil
  end
end
