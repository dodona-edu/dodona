class SeriesProgressOptionalToggle < ActiveRecord::Migration[5.2]
  def change
    add_column :series, :progress_enabled, :boolean, null: false, default: true
  end
end
