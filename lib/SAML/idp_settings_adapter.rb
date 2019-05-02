class MyIdPSettingsAdapter
  ASSERTION_ERROR_INSTITUTIONS_ENTITY_IDS = %w(https://idp.hogent.be/idp https://idp.howest.be/idp/shibboleth)

  def self.settings(idp)
    return {} if idp.nil?
    institution = Institution.find_by(short_name: idp) || Institution.find_by(entity_id: idp)
    return {} if institution.nil?
    context = ASSERTION_ERROR_INSTITUTIONS_ENTITY_IDS.include?(institution.entity_id) ? false : ""
    {
      idp_slo_target_url: institution.slo_url,
      idp_sso_target_url: institution.sso_url,
      idp_cert: institution.certificate,
      authn_context: context
    }
  end

  def self.entity_id(params)
    if params[:idp]
      params[:idp]
    elsif params[:SAMLResponse]
      OneLogin::RubySaml::Response.new(
          params[:SAMLResponse],
          settings: Devise.saml_config,
          allowed_clock_drift: Devise.allowed_clock_drift_in_seconds
      ).issuers.first
    end
  end
end
