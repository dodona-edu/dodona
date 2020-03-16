module NotificationsHelper
  def base_notifiable_url_params(notification)
    return { controller: 'exports', action: 'index' } if notification.notifiable_type == 'Export'
    return { controller: 'submissions', action: 'show', id: notification.notifiable.id } if notification.notifiable_type == 'Submission'
  end

  def notifiable_url(notification)
    return exports_path(highlighted: notification.notifiable.id) if notification.notifiable_type == 'Export'
    return submission_path(notification.notifiable, anchor: 'code') if notification.notifiable_type == 'Submission'
  end

  def notifiable_icon(notification)
    return 'mdi-file-download-outline' if notification.notifiable_type == 'Export'
    return 'mdi-comment-account-outline' if notification.notifiable_type == 'Submission'
  end
end
