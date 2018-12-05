class AddFsKeyToSubmission < ActiveRecord::Migration[5.2]
  def change
    add_column :submissions, :fs_key, :string, limit: 24
    add_index :submissions, :fs_key, unique: true
  end
end
