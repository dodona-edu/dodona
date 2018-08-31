class CreateLabels < ActiveRecord::Migration[5.1]
  def change
    create_table :labels do |t|
      t.string :name, null: false
      t.integer :color, null: false
    end
    add_index :labels, :name, unique: true
  end
end
