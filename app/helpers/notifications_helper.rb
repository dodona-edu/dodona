module NotificationsHelper
  def base_notifiable_url_params(notification)
    return { controller: 'submissions', action: 'show', id: notification.notifiable_id } if notification.notifiable_type == 'Submission'

    { controller: 'evaluations', action: 'overview', id: notification.notifiable_id } if notification.notifiable_type == 'Evaluation'
  end

  def notifiable_url(notification)
    return submission_path(notification.notifiable_id, anchor: 'code') if notification.notifiable_type == 'Submission'

    overview_evaluation_path(notification.notifiable_id) if notification.notifiable_type == 'Evaluation'
  end

  def notifiable_icon(notification)
    return 'mdi-comment-account-outline' if notification.notifiable_type == 'Submission'

    'mdi-comment-multiple-outline' if notification.notifiable_type == 'Evaluation'
  end
end
