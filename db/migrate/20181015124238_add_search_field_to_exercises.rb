class AddSearchFieldToExercises < ActiveRecord::Migration[5.2]
  def change
    add_column :exercises, :search, :string
    Exercise.all.each do |ex|
      ex.update(search: "#{ex.status} #{ex.access} #{ex.name_nl} #{ex.name_en} #{ex.path}")
    end
  end
end
