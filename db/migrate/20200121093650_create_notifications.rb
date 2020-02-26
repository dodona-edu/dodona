class CreateNotifications < ActiveRecord::Migration[6.0]
  def change
    create_table :notifications do |t|
      t.string :message, null: false
      t.boolean :read, default: false, null: false

      t.references :user, foreign_key: true, null: false, type: :integer
      t.references :notifiable, polymorphic: true

      t.timestamps
    end
  end
end
