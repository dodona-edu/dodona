class RemoveExportNotifications < ActiveRecord::Migration[7.1]
  def change
    Notification.where(notifiable_type: 'Export').destroy_all
  end
end
