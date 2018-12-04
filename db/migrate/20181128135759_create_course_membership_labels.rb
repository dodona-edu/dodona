class CreateCourseMembershipLabels < ActiveRecord::Migration[5.2]
  def change
    create_table :course_membership_labels do |t|
      t.integer :course_membership_id, null: false
      t.bigint :course_label_id, null: false
    end

    add_foreign_key :course_membership_labels, :course_labels, on_delete: :cascade
    add_foreign_key :course_membership_labels, :course_memberships, on_delete: :cascade

    add_index :course_membership_labels, [:course_label_id, :course_membership_id], unique: true, name: 'unique_label_and_course_membership_index'
  end
end
