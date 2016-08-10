class AddRunnerToJudge < ActiveRecord::Migration[5.0]
  def change
    add_column :judges, :runner, :string, null: false
  end
end
