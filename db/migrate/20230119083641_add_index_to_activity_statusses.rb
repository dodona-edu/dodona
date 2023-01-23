class AddIndexToActivityStatusses < ActiveRecord::Migration[7.0]
  def change
    add_index :activity_statuses, [:series_id, :started, :user_id, :last_submission_id], name: 'index_as_on_series_and_started_and_user_and_last_submission'
  end
end
