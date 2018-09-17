class CreateRepositoryAdmin < ActiveRecord::Migration[5.1]
  def change
    create_table :repository_admins do |t|
      t.integer :repository_id, null: false
      t.integer :user_id, null: false
    end

    add_index :repository_admins, [:repository_id, :user_id], unique: true
    add_foreign_key :repository_admins, :repositories
    add_foreign_key :repository_admins, :users
  end
end
