module SeasonalHelper
  def christmas(current_time)
    current_time.month == 12
  end

  # returns seasonal class
  def series_status_overlay
    current_time = Time.now.in_time_zone(config.time_zone)

    return 'christmas' if christmas(current_time)

    nil
  end
end
