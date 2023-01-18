class AddIndexesToActivityStatuses < ActiveRecord::Migration[7.0]
  def change
    add_index :activity_statuses, [:accepted, :user_id, :series_id], name: 'index_activity_statuses_on_accepted_and_user_id_and_series_id'
    add_index :activity_statuses, [:started, :user_id, :series_id], name: 'index_activity_statuses_on_started_and_user_id_and_series_id'
    add_index :activity_statuses, [:user_id, :series_id, :last_submission_id], name: 'index_as_on_user_and_series_and_last_submission'
  end
end
