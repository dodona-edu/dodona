class FixUniqueIndexes < ActiveRecord::Migration[6.0]
  def change
    remove_index :api_tokens, [:user_id, :description] if index_exists?(:api_tokens, [:user_id, :description])
    add_index :api_tokens, [:user_id, :description], unique: true

    remove_index :institutions, :identifier if index_exists?(:institutions, :identifier)
    add_index :institutions, :identifier, unique: true

    remove_index :repositories, :name if index_exists?(:repositories, :name)
    add_index :repositories, :name, unique: true

    remove_index :series_memberships, [:series_id, :exercise_id] if index_exists?(:series_memberships, [:series_id, :exercise_id])
    add_index :series_memberships, [:series_id, :exercise_id], unique: true

    remove_index :users, :email if index_exists?(:users, :email)
    add_index :users, :email, unique: true
  end
end
