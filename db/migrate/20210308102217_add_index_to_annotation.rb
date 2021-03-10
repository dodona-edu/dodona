class AddIndexToAnnotation < ActiveRecord::Migration[6.1]
  def change
    add_column :annotations, :course_id, :integer
    Annotation.find_each do |a|
      a.update(course_id: a.submission.course_id)
    end
    change_column_null :annotations, :course_id, false
    add_foreign_key :annotations, :courses
    add_index :annotations, [:course_id, :type, :question_state]
  end
end
