class AddCloneStatusToJudges < ActiveRecord::Migration[6.1]
  def change
    add_column :judges, :clone_status, :integer, null: false, default: 3
    change_column :judges, :clone_status, :integer, null: false, default: 1
  end
end
