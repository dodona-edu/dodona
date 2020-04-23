class CreateActivityReadStates < ActiveRecord::Migration[6.0]
  def change
    create_table :activity_read_states do |t|
      t.integer :activity_id, null: false
      t.integer :course_id, null: true
      t.integer :user_id, null: false

      t.timestamps
    end

    add_foreign_key :activity_read_states, :activities, on_delete: :cascade
    add_foreign_key :activity_read_states, :courses, on_delete: :cascade
    add_foreign_key :activity_read_states, :users, on_delete: :cascade
    add_index :activity_read_states, [:activity_id, :course_id, :user_id], unique: true, name: 'activity_read_states_unique'
  end
end
