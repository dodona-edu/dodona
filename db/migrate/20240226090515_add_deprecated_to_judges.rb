class AddDeprecatedToJudges < ActiveRecord::Migration[7.1]
  def change
    add_column :judges, :deprecated, :boolean, default: false, null: false
  end
end
