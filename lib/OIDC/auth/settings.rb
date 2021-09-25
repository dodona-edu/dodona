require 'omniauth'

module OIDC
  module Auth
    module Settings
      KEY_PATH = '/home/dodona/key.pem'.freeze

      def base_settings
        # Support only third-parties that are discoverable.
        {
          client_options: {
            redirect_uri: "https://#{Rails.configuration.default_host}/users/auth/oidc/callback"
          },
          discovery: true,
          response_mode: :form_post,
          response_type: :code,
          scope: [:openid, :profile]
        }
      end

      def provider_settings(provider)
        raise 'Not an OIDC provider.' unless provider.is_a?(Provider::Oidc)

        {
          client_auth_method: :jwt_bearer,
          client_options: {
            identifier: provider.client_id,
            private_key: private_key
          },
          issuer: provider.issuer,
          state: lambda { format("%d-%s", provider.id, SecureRandom::hex(16)) }
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
