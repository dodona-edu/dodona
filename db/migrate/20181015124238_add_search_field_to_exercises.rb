class AddSearchFieldToExercises < ActiveRecord::Migration[5.2]
  def change
    add_column :exercises, :search, :string, :limit => 4096
    Exercise.find_each do |ex|
      ex.set_search
      ex.save
    end
  end
end
