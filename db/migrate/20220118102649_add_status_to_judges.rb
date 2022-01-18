class AddStatusToJudges < ActiveRecord::Migration[6.1]
  def change
    add_column :judges, :status, :integer
  end
end
