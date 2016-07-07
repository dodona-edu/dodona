class CreateCourseMemberships < ActiveRecord::Migration[5.0]
  def change
    create_table :course_memberships do |t|
      t.references :course, index: true
      t.references :user, index: true
      t.integer :status

      t.timestamps
    end
  end
end
