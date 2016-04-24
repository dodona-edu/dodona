class CreateSubmissions < ActiveRecord::Migration[5.0]
  def change
    create_table :submissions do |t|
      t.references :exercise, foreign_key: true
      t.references :user, foreign_key: true
      t.text :code
      t.integer :result, index: true, default: 0

      t.timestamps
    end
  end
end
