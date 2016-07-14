class CreateRepositories < ActiveRecord::Migration[5.0]
  def change
    create_table :repositories do |t|
      t.string :name
      t.string :remote
      t.string :path
      t.references :judge, foreign_key: true

      t.timestamps
    end
  end
end
