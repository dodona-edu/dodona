class UpdateIndexToUsersToEmail < ActiveRecord::Migration[7.0]
  def change
    remove_index :users, :email if index_exists?(:users, :email)
    add_index :users, [:email, :institution_id], unique: true
  end
end
