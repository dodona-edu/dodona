module OmniAuth
  module Strategies
    class SAML
      class Settings
        ASSERTION_ERROR_INSTITUTIONS_ENTITY_IDS = %w(https://idp.hogent.be/idp https://idp.howest.be/idp/shibboleth)

        def self.defaults
          # Load the certificate and private key if on staging/production.
          certificate = IO.read('/home/dodona/cert.pem') if File.file?('/home/dodona/cert.pem')
          private_key = IO.read('/home/dodona/key.pem') if File.file?('/home/dodona/key.pem')

          {
              assertion_consumer_service_binding: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
              assertion_consumer_service_url: "https://#{Socket.gethostbyname(Socket.gethostname).first.downcase}/users/saml/auth",
              authn_context: '',
              certificate: certificate,
              issuer: "https://#{Socket.gethostbyname(Socket.gethostname).first.downcase}/users/saml/metadata",
              name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
              private_key: private_key,
              security: {
                  authn_requests_signed: true,
                  digest_method: XMLSecurity::Document::SHA256,
                  embed_sign: true,
                  signature_method: XMLSecurity::Document::RSA_SHA256
              }
          }
        end

        def self.for_institution(institution)
          context = ASSERTION_ERROR_INSTITUTIONS_ENTITY_IDS.include?(institution.entity_id) ? false : ""
          {
              authn_context: context,
              idp_cert: institution.certificate,
              idp_slo_target_url: institution.slo_url,
              idp_sso_target_url: institution.sso_url
          }
        end
      end
    end
  end
end
