class RemoveRunnerColumnFromJudge < ActiveRecord::Migration[6.0]
  def change
    remove_column :judges, :runner
  end
end
