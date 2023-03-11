class RemoveIndianioTokenFromSeries < ActiveRecord::Migration[7.0]
  def change
    remove_column :series, :indianio_token
  end
end
