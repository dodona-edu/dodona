class RemoveAuthenticationDataFromInstitutions < ActiveRecord::Migration[6.0]
  def change
    remove_columns :institutions, :sso_url, :slo_url, :certificate, :entity_id, :identifier, :provider
  end
end
