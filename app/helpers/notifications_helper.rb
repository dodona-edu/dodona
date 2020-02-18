module NotificationsHelper
  def notifiable_url(notification)
    return exports_path if notification.notifiable_type == 'Export'
  end

  def notifiable_icon(notification)
    return 'mdi-file-download-outline' if notification.notifiable_type == 'Export'
  end
end
