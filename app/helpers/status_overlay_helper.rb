module StatusOverlayHelper
  def christmas(current_time)
    return true
    # return current_time.month == 12 && current_time.day.between?(25, 31)
  end

  # returns [class]
  def status_overlay()
    current_time = Time.now

    return 'christmas' if christmas(current_time)

    nil
  end
end
