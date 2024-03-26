# Flemish government is an extension upon the OpenIDConnect Protocol
# Changes are applied to support the specific requirements of ACM IDM.
module FlemishGovernment
  module Auth
    module OmniAuth
      class Setup
        KEY_PATH = '/home/dodona/key.pem'.freeze

        def self.call(env)
          new(env).setup
        end

        def initialize(env)
          @env = env
        end

        def setup
          @env['omniauth.params'] ||= {}
          @env['omniauth.strategy'].options.merge!(configure)
        end

        def configure
          {
            client_options: {
              identifier: Rails.application.credentials.acmidm_client_id,
              private_key: private_key,
              redirect_uri: "https://#{@env['HTTP_HOST']}/users/auth/flemish_government/callback"
            },
            discovery: true,
            response_mode: :form_post,
            response_type: :code,
            scope: [:openid, :profile, :vo, :ov_leerling],
            client_auth_method: :jwt_bearer,
            issuer: "https://authenticatie-ti.vlaanderen.be/op",
          }
        end

        private

        def private_key_path
          # This function allows to override the key path in tests.
          KEY_PATH
        end

        def private_key
          # Only load the key if it exists (staging / production).
          return nil unless File.file?(private_key_path)

          # Parse the key.
          @private_key ||= OpenSSL::PKey::RSA.new File.read(private_key_path)
        end
      end
    end
  end
end
