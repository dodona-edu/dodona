class CreateSeries < ActiveRecord::Migration[5.0]
  def change
    create_table :series do |t|
      t.references :course, foreign_key: true
      t.string :name, index: true
      t.text :description
      t.integer :visibility, index: true
      t.integer :order

      t.timestamps
    end
  end
end
