class CreateSavedAnnotations < ActiveRecord::Migration[7.0]
  def change
    create_table :saved_annotations do |t|
      t.string :title, null: false
      t.text :annotation_text, size: :medium
      t.references :user, foreign_key: true, type: :integer, null: false
      t.references :exercise, foreign_key: { to_table: :activities }, type: :integer, null: false
      t.references :course, foreign_key: true, type: :integer, null: false

      t.timestamps

      t.index [:title, :user_id, :exercise_id, :course_id], unique: true, name: "index_saved_annotations_title_uid_eid_cid"
    end

    change_table :annotations do |t|
      t.references :saved_annotation, foreign_key: true
    end
  end
end
