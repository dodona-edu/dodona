class RenameSubmissionExerciseToActivity < ActiveRecord::Migration[6.0]
  def change
    rename_column :submissions, :exercise_id, :activity_id
  end
end
