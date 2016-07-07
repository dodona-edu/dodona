class CreateCourses < ActiveRecord::Migration[5.0]
  def change
    create_table :courses do |t|
      t.string :name
      t.string :year
      t.string :secret
      t.boolean :open

      t.timestamps
    end
  end
end
