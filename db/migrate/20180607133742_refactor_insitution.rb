class RefactorInsitution < ActiveRecord::Migration[5.1]
  def change
    create_table :saml_providers do |t|
      t.string :name, :short_name, :logo, :sso_url, :slo_url, :entity_id
      t.text :certificate

      t.timestamps
    end

    change_table :institutions do |t|
      t.integer :saml_provider_id
      add_foreign_key :saml_provider_id, :saml_providers
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
