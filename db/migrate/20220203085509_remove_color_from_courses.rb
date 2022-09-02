class RemoveColorFromCourses < ActiveRecord::Migration[6.1]
  def change
    remove_column :courses, :color
  end
end
