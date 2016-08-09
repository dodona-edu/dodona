class AddRendererToJudge < ActiveRecord::Migration[5.0]
  def change
    add_column :judges, :renderer, :string, null: false
  end
end
