class CreateExerciseStatuses < ActiveRecord::Migration[6.0]
  def change
    create_table :exercise_statuses do |t|
      t.boolean :accepted, default: false, null: false # status of the last submission
      t.boolean :accepted_before_deadline, default: false, null: false
      t.boolean :solved, default: false, null: false # whether any correct submission exists
      t.boolean :started, default: false, null: false # whether any submission exists

      t.datetime :solved_at, null: true # timestamp of the first correct submission

      t.integer :exercise_id, null: false
      t.integer :series_id, null: true
      t.integer :user_id, null: false

      t.timestamps
    end

    add_foreign_key :exercise_statuses, :exercises, on_delete: :cascade
    add_foreign_key :exercise_statuses, :series, on_delete: :cascade
    add_foreign_key :exercise_statuses, :users, on_delete: :cascade
    add_index :exercise_statuses, [:exercise_id, :series_id, :user_id], unique: true
  end
end
