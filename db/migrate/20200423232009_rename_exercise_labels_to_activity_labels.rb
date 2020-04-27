class RenameExerciseLabelsToActivityLabels < ActiveRecord::Migration[6.0]
  def change
    rename_table :exercise_labels, :activity_labels
  end
end
