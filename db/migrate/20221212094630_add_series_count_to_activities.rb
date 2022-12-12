class AddSeriesCountToActivities < ActiveRecord::Migration[7.0]
  def change
    add_column :activities, :series_count, :integer, :default => 0, :null => false
    Activity.reset_column_information
    Activity.all.each do |e|
      Activity.reset_counters e.id, :series_memberships
    end
  end
end
