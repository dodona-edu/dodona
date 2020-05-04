class CourseMembershipForeignKeys < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :course_memberships, :courses, on_delete: :cascade
    add_foreign_key :course_memberships, :users, on_delete: :cascade
    change_column_null :course_memberships, :status, false
    change_column_null :course_memberships, :user_id, false
    change_column_null :course_memberships, :course_id, false
  end
end
