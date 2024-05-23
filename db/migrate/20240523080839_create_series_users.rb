class CreateSeriesUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :series_users do |t|
      t.primary_key :id
      t.integer :user_id
      t.integer :series_id

      t.timestamps
    end
    add_index :series_users, :series_id
    add_index :series_users, [:user_id, :series_id], unique: true
  end
end
