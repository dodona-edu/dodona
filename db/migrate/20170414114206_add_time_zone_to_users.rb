class AddTimeZoneToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :time_zone, :string, default: "Brussels"
    execute "UPDATE users SET users.time_zone = 'Seoul' WHERE users.email like '%ghent.ac.kr'"
  end
end
