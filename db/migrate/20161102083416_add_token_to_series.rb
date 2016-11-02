class AddTokenToSeries < ActiveRecord::Migration[5.0]
  def change
    add_column :series, :token, :string
    add_index :series, :token
  end
end
