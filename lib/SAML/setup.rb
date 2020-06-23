module OmniAuth
  module Strategies
    class SAML
      class Setup
        ASSERTION_ERROR_INSTITUTIONS_ENTITY_IDS = %w(https://idp.hogent.be/idp https://idp.howest.be/idp/shibboleth)

        def self.call(env)
          new(env).setup
        end

        def initialize(env)
          @env = env
        end

        def setup
          @env["omniauth.strategy"].options.merge!(settings)
          @env["omniauth.strategy"].options.merge!(configure)
        end

        private

        def configure
          # Parse the request parameters.
          params = Rack::Request.new(@env).params.symbolize_keys

          # Obtain the id of the institution from the parameters.
          id = params[:institution]
          return failure if id.blank?

          # Obtain the saml parameters for the institution.
          institution = Institution.find_by(id: id)
          return failure if institution.nil?

          # Configure the parameters.
          context = ASSERTION_ERROR_INSTITUTIONS_ENTITY_IDS.include?(institution.entity_id) ? false : ""
          {
              authn_context: context,
              idp_cert: institution.certificate,
              idp_slo_target_url: institution.slo_url,
              idp_sso_target_url: institution.sso_url
          }
        end

        def failure
          # TODO redirect
          raise "Invalid institution."
        end

        def settings
          # Load the certificate and private key if on staging/production.
          certificate = IO.read('/home/dodona/cert.pem') if File.file?('/home/dodona/cert.pem')
          private_key = IO.read('/home/dodona/key.pem') if File.file?('/home/dodona/key.pem')

          {
              assertion_consumer_service_binding: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
              assertion_consumer_service_url: "https://#{Socket.gethostbyname(Socket.gethostname).first.downcase}/users/auth/saml",
              authn_context: '',
              certificate: certificate,
              issuer: "https://#{Socket.gethostbyname(Socket.gethostname).first.downcase}/users/saml/metadata",
              name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
              private_key: private_key,
              security: {
                  authn_requests_signed: true,
                  embed_sign: true
              }
          }
        end
      end
    end
  end
end
