module NotificationsHelper
  def notifiable_url(notification)
    return exports_path if notification.notifiable_type == 'Export'
  end
end
