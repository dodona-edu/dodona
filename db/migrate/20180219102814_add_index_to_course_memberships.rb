class AddIndexToCourseMemberships < ActiveRecord::Migration[5.1]
  def change
    add_index :course_memberships, [:user_id, :course_id], unique: true
  end
end
