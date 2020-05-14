class ActivityStatusIndexSeriesNonNil < ActiveRecord::Migration[6.0]
  def change
    add_column :activity_statuses, :series_id_non_nil, :integer

    add_index :activity_statuses, :activity_id
    add_index :activity_statuses, [:user_id, :series_id_non_nil, :activity_id], unique: true, name: 'index_on_user_id_series_id_non_nil_activity_id'
    remove_index :activity_statuses, [:activity_id, :series_id, :user_id]
  end
end
