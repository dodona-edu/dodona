class AddLtiSettingsToProviders < ActiveRecord::Migration[6.0]
  def change
    add_column :providers, :authorization_uri, :string, null: true
    add_column :providers, :client_id, :string, null: true
    add_column :providers, :issuer, :string, null: true
    add_column :providers, :jwks_uri, :string, null: true
  end
end
