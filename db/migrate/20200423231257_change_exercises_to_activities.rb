class ChangeExercisesToActivities < ActiveRecord::Migration[6.0]
  def change
    rename_table :exercises, :activities

    add_column :activities, :type, :string, null: false, default: 'Exercise'

    # Rename foreign keys.
    rename_column :exercise_labels, :exercise_id, :activity_id
    rename_column :exercise_statuses, :exercise_id, :activity_id
    rename_column :series_memberships, :exercise_id, :activity_id

    # Rename other columns.
    rename_column :series, :exercises_visible, :activities_visible
  end
end
