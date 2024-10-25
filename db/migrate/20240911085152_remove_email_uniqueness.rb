class RemoveEmailUniqueness < ActiveRecord::Migration[7.2]
  def change
    remove_index :users, name: "index_users_on_email_and_institution_id"
    remove_index :users, name: "index_users_on_username_and_institution_id"
  end
end
