class AddActivityNumbersEnabledToSeries < ActiveRecord::Migration[7.0]
  def change
    add_column :series, :activity_numbers_enabled, :boolean, default: false, null: false
  end
end
