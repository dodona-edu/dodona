class AddSeenAtToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :seen_at, :datetime
  end
end
