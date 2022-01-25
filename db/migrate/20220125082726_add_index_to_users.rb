class AddIndexToUsers < ActiveRecord::Migration[6.1]
  def change
    add_index :users, :seen_at
  end
end
