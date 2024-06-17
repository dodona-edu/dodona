class AddSeriesIdToActivityReadState < ActiveRecord::Migration[7.1]
  def change
    add_column :activity_read_states, :series_id, :integer
    add_index :activity_read_states, :series_id
  end
end
