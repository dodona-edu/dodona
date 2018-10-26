class AddSearchFieldToExercises < ActiveRecord::Migration[5.2]
  def change
    add_column :exercises, :search, :string, :limit => 4096
  end
end
