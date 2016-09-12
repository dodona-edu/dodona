class AddIndexToJudges < ActiveRecord::Migration[5.0]
  def change
    add_index :judges, :name, unique: true
  end
end
