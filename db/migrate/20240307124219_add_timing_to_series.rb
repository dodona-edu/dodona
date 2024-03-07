class AddTimingToSeries < ActiveRecord::Migration[7.1]
  def change
    add_column :series, :visibility_start, :datetime
    add_column :series, :visibility_end, :datetime
  end
end
