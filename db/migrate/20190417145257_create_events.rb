class CreateEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :events do |t|
      t.integer :event_type, null: false
      t.integer :user_id
      t.string :message, null: false

      t.timestamps
    end

    add_foreign_key :events, :users, on_delete: :cascade
  end
end
