class CreateSeriesMemberships < ActiveRecord::Migration[5.0]
  def change
    create_table :series_memberships do |t|
      t.references :series, foreign_key: true
      t.references :exercise, foreign_key: true
      t.integer :order, :default => 999

      t.timestamps
    end
  end
end
