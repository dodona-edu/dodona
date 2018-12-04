class CreateCourseLabels < ActiveRecord::Migration[5.2]
  def change
    create_table :course_labels do |t|
      t.integer :course_id, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_foreign_key :course_labels, :courses, on_delete: :cascade
    add_index :course_labels, [:course_id, :name], unique: true
  end
end
