module SeasonalHelper
  def christmas(current_time)
    current_time.month == 12 && current_time.day > 6
  end

  def valentine(current_time)
    current_time.month == 2 && current_time.day == 14
  end

  def mario_day(current_time)
    current_time.month == 3 && current_time.day == 10
  end

  def pi_day(current_time)
    current_time.month == 3 && current_time.day == 14
  end

  # returns seasonal class
  def series_status_overlay
    current_time = Time.now.in_time_zone(config.time_zone)

    return 'christmas' if christmas(current_time)
    return 'valentine' if valentine(current_time)
    return 'mario-day' if mario_day(current_time)
    return 'pi-day'    if pi_day(current_time)

    nil
  end
end
