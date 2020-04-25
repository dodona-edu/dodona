class RenameExerciseStatusToActivityStatus < ActiveRecord::Migration[6.0]
  def change
    rename_table :exercise_statuses, :activity_statuses
  end
end
