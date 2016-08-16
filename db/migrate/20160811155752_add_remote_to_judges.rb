class AddRemoteToJudges < ActiveRecord::Migration[5.0]
  def change
    add_column :judges, :remote, :string
  end
end
