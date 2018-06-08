class RefactorInsitution < ActiveRecord::Migration[5.1]
  def change
    create_table :providers do |t|
      t.column :type, :string, null: false
      t.index :type

      # Provider (common)
      t.string :name, :short_name, :logo

      # SAMLProvider
      t.string :sso_url, :slo_url, :entity_id
      t.text :certificate

      # OAuthProvider
      t.string :site, :authorize_url, :token_url, :info_url, :client_id, :client_secret

      t.timestamps
    end

    change_table :institutions do |t|
      t.integer :provider_id
      add_foreign_key :provider_id, :providers
    end

    fields = %i[name short_name logo sso_url slo_url entity_id certificate]
    Institution.all.each do |institution|
      provider = SAMLProvider.new
      fields.each do |field|
        provider[field] = inst[field]
      end
      provider.save
      institution.update(provider: provider)
    end

    change_table :institutions do |t|
      t.remove :logo, :sso_url, :slo_url, :certificate, :entity_id
    end
  end
end
