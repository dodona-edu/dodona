class SetDefaultJudgeForRepositories < ActiveRecord::Migration[7.2]
  def change
    change_column_default :repositories, :judge_id, from: nil, to: 17
  end
end
