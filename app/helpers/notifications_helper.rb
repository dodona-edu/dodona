module NotificationsHelper
  def base_notifiable_url_params(notification)
    return { controller: 'exports', action: 'index' } if notification.notifiable_type == 'Export'
    return { controller: 'submissions', action: 'show', id: notification.notifiable_id } if notification.notifiable_type == 'Submission'
    return { controller: 'review_sessions', action: 'overview', id: notification.notifiable_id } if notification.notifiable_type == 'ReviewSession'
  end

  def notifiable_url(notification)
    return exports_path(highlighted: notification.notifiable_id) if notification.notifiable_type == 'Export'
    return submission_path(notification.notifiable_id, anchor: 'code') if notification.notifiable_type == 'Submission'
    return overview_review_session_path(notification.notifiable_id) if notification.notifiable_type == 'ReviewSession'
  end

  def notifiable_icon(notification)
    return 'mdi-file-download-outline' if notification.notifiable_type == 'Export'
    return 'mdi-comment-account-outline' if notification.notifiable_type == 'Submission'
    return 'mdi-comment-multiple-outline' if notification.notifiable_type == 'ReviewSession'
  end
end
