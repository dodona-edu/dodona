class CreateVersions < ActiveRecord::Migration[5.2]
  def change
    create_table :versions do |t|
      t.string :tag, null: false
      t.date :release, null: false
      t.boolean :draft, null: false, default: true

      t.timestamps
    end
    add_index :versions, :tag, unique: true
  end
end
