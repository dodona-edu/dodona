class AddSignInAtToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :sign_in_at, :datetime
  end
end
