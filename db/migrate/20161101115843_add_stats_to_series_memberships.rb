class AddStatsToSeriesMemberships < ActiveRecord::Migration[5.0]
  def change
    add_column :series_memberships, :users_correct, :integer
    add_column :series_memberships, :users_attempted, :integer
  end
end
