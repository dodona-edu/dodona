class AddCloneStatusToRepositories < ActiveRecord::Migration[6.1]
  def change
    add_column :repositories, :clone_status, :integer, null: false, default: 3
    change_column :repositories, :clone_status, :integer, null: false, default: 1
  end
end
