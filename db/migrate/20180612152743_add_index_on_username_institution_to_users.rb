class AddIndexOnUsernameInstitutionToUsers < ActiveRecord::Migration[5.1]
  def change
    add_index :users, [:username, :institution_id], unique: true
  end
end
