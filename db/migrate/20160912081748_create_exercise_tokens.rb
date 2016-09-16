class CreateExerciseTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :exercise_tokens do |t|
      t.string :token
      t.references :exercise, foreign_key: true

      t.timestamps
    end
  end
end
