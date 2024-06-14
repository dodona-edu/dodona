class AddSeriesIdToSubmissions < ActiveRecord::Migration[7.1]
  def change
    add_column :submissions, :series_id, :integer
    add_index :submissions, :series_id
  end
end
