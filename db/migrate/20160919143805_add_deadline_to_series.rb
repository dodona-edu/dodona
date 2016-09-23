class AddDeadlineToSeries < ActiveRecord::Migration[5.0]
  def change
    add_column :series, :deadline, :datetime
    add_index :series, :deadline

  end
end
