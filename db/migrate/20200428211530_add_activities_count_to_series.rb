class AddActivitiesCountToSeries < ActiveRecord::Migration[6.0]
  def change
    add_column :series, :activities_count, :integer
    Series.find_each do |series|
      Series.reset_counters(series.id, :series_memberships)
    end
  end
end
