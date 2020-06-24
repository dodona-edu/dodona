class CreateProviders < ActiveRecord::Migration[6.0]
  def change
    create_table :providers do |t|
      t.string :type, null: false, default: 'Provider::Saml'
      t.bigint :institution_id, null: false

      # Generic.
      t.string :identifier, null: true

      # SAML.
      t.text :certificate, null: true
      t.string :entity_id, null: true
      t.string :slo_url, null: true
      t.string :sso_url, null: true

      t.timestamps
    end

    add_foreign_key :providers, :institutions, on_delete: :cascade
  end
end
