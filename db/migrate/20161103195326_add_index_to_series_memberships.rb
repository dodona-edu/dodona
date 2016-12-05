class AddIndexToSeriesMemberships < ActiveRecord::Migration[5.0]
  def change
    add_index :series_memberships, [:series_id, :exercise_id]
  end
end
