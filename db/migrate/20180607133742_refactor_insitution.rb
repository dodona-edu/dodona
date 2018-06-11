class RefactorInsitution < ActiveRecord::Migration[5.1]
  def change
    create_table :saml_providers do |t|
      t.string :name, :short_name, :logo, :sso_url, :slo_url, :entity_id
      t.text :certificate

      t.timestamps
    end

    change_table :institutions do |t|
      t.belongs_to :saml_provider
    end

    fields = %i[name short_name logo sso_url slo_url entity_id certificate]
    Institution.all.each do |institution|
      provider = SAMLProvider.new
      fields.each do |field|
        provider[field] = institution[field]
      end
      provider.save
      institution.update(saml_provider: provider)
    end

    change_table :institutions do |t|
      t.remove :logo, :sso_url, :slo_url, :certificate, :entity_id
    end
  end
end
