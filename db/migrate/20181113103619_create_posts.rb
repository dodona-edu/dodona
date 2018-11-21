class CreatePosts < ActiveRecord::Migration[5.2]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.date :release, null: false
      t.boolean :draft, null: false, default: true

      t.timestamps
    end
    add_index :posts, [:title, :release], unique: true
  end
end
