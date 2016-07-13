class CreateJudges < ActiveRecord::Migration[5.0]
  def change
    create_table :judges do |t|
      t.string :name
      t.string :image
      t.string :path

      t.timestamps
    end
  end
end
