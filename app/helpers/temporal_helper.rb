module TemporalHelper
  def christmas(current_time)
    return current_time.month == 12 && current_time.day.between?(25, 31)
  end

  # returns temporal class
  def series_status_overlay()
    current_time = Time.now

    return 'christmas' if christmas(current_time)

    nil
  end
end
