class ActivityStatusIndexSeriesNonNilDestructive < ActiveRecord::Migration[6.0]
  def change
    ActivityStatus.where(series_id: nil, series_id_non_nil: nil).delete_all
    execute 'UPDATE activity_statuses SET series_id_non_nil = series_id WHERE series_id IS NOT NULL'

    change_column :activity_statuses, :series_id_non_nil, :integer, null: false
  end
end
