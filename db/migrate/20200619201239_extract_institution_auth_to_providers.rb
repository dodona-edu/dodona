class ExtractInstitutionAuthToProviders < ActiveRecord::Migration[6.0]
  def change
    # Google Suite.
    Institution.google_oauth2.find_each do |institution|
      Provider::GSuite.create institution: institution,
                              identifier: institution.identifier
    end

    # Office 365.
    Institution.office365.find_each do |institution|
      Provider::Office365.create institution: institution,
                                 identifier: institution.identifier
    end

    # SAML.
    Institution.saml.find_each do |institution|
      Provider::Saml.create institution: institution,
                            entity_id: institution.entity_id,
                            certificate: institution.certificate,
                            slo_url: institution.slo_url,
                            sso_url: institution.sso_url
    end

    # SmartSchool.
    Institution.smartschool.find_each do |institution|
      Provider::Smartschool.create institution: institution,
                                   identifier: institution.identifier
    end
  end
end
