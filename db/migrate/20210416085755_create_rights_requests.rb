class CreateRightsRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :rights_requests do |t|
      t.references :user, foreign_key: true, null: false, type: :integer
      t.string :institution_name
      t.text :context, null: false

      t.timestamps
    end
  end
end
