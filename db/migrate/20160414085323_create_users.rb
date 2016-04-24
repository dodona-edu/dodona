class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :username, index: true
      t.string :ugent_id
      t.string :first_name
      t.string :last_name
      t.string :email
      t.integer :permission, default: 0

      t.timestamps
    end
  end
end
