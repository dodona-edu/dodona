class OmniauthSamlSetup
  ASSERTION_ERROR_INSTITUTIONS_ENTITY_IDS = %w(https://idp.hogent.be/idp https://idp.howest.be/idp/shibboleth)

  def self.call(env)
    new(env).setup
  end

  def initialize(env)
    @env = env
  end

  def setup
    @env["omniauth.strategy"].options.merge!(configure)
  end

  private

  def configure
    # Parse the request parameters.
    params = Rack::Request.new(@env).params.symbolize_keys

    # Obtain the short name of the institution.
    short_name = params[:institution]
    return error_handle if short_name.blank?

    # Obtain the saml parameters for the institution.
    institution = Institution.find_by(short_name: short_name)
    return error_handle if institution.nil?

    # Configure the parameters.
    context = ASSERTION_ERROR_INSTITUTIONS_ENTITY_IDS.include?(institution.entity_id) ? false : ""
    {
        authn_context: context,
        idp_cert: institution.certificate,
        idp_slo_target_url: institution.slo_url,
        idp_sso_target_url: institution.sso_url
    }
  end

  def error_handle
    # TODO redirect
    raise "Invalid institution."
  end
end
