class MyIdPSettingsAdapter
  def self.settings(idp)
    institution = Institution.find_by(short_name: idp) || Institution.find_by(entity_id: idp)
    return {} if institution.nil?
    {
      idp_slo_target_url: institution.slo_url,
      idp_sso_target_url: institution.sso_url,
      idp_cert: institution.certificate
    }
  end

  def self.entity_id(params)
    if params[:idp]
      params[:idp]
    elsif params[:SAMLResponse]
      OneLogin::RubySaml::Response.new(
        params[:SAMLResponse],
        allowed_clock_drift: Devise.allowed_clock_drift_in_seconds
      ).issuers.first
    end
  end
end
