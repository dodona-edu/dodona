class CreateExerciseTags < ActiveRecord::Migration[5.1]
  def change
    create_table :exercise_tags do |t|
      t.integer :exercise_id, null: false
      t.bigint :tag_id, null: false
    end

    add_foreign_key :exercise_tags, :exercises
    add_foreign_key :exercise_tags, :tags
    add_index :exercise_tags, [:exercise_id, :tag_id], unique: true
  end
end
