class CreateExerciseLabels < ActiveRecord::Migration[5.1]
  def change
    create_table :exercise_labels do |t|
      t.integer :exercise_id, null: false
      t.bigint :label_id, null: false
    end

    add_foreign_key :exercise_labels, :exercises
    add_foreign_key :exercise_labels, :labels
    add_index :exercise_labels, [:exercise_id, :label_id], unique: true
  end
end
