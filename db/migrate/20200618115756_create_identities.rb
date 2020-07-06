class CreateIdentities < ActiveRecord::Migration[6.0]
  def change
    create_table :identities do |t|
      t.string :identifier, null: false
      t.bigint  :provider_id, null: false
      t.integer :user_id, null: false

      t.timestamps
    end

    add_foreign_key :identities, :providers, on_delete: :cascade
    add_foreign_key :identities, :users, on_delete: :cascade
    add_index :identities, [:provider_id, :identifier], unique: true
    add_index :identities, [:provider_id, :user_id], unique: true
  end
end
