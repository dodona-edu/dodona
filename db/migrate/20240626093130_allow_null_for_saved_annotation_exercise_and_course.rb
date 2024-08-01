class AllowNullForSavedAnnotationExerciseAndCourse < ActiveRecord::Migration[7.1]
  def change
    change_column_null :saved_annotations, :exercise_id, true
    change_column_null :saved_annotations, :course_id, true
  end
end
