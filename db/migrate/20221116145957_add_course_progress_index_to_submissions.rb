class AddCourseProgressIndexToSubmissions < ActiveRecord::Migration[7.0]
  def change
    add_index :submissions, [:status, :course_id, :exercise_id, :user_id], :name => 'st_co_ex_us_index'
  end
end
