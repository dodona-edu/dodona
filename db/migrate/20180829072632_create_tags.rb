class CreateTags < ActiveRecord::Migration[5.1]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.integer :color, null: false
    end
    add_index :tags, :name, unique: true
  end
end
