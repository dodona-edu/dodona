class CreateExercises < ActiveRecord::Migration[5.0]
  def change
    create_table :exercises do |t|
      t.string :name, index: true
      t.integer :visibility, default: 0

      t.timestamps
    end
  end
end
