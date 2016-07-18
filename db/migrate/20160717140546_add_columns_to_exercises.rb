class AddColumnsToExercises < ActiveRecord::Migration[5.0]
  def change
    rename_column :exercises, :name, :name_nl
    add_column :exercises, :name_en, :string, after: :name_nl
    add_column :exercises, :path, :string
    add_column :exercises, :description_format, :string
    add_reference :exercises, :repository, foreign_key: true
    add_reference :exercises, :judge, foreign_key: true
    add_index :exercises, [:path, :repository_id], unique: true
  end
end
