class AddExerciseStatusCourseIndexToSubmissions < ActiveRecord::Migration[7.0]
  def change
    add_index :submissions, [:exercise_id, :status, :course_id], name: 'ex_st_co_idx'
  end
end
