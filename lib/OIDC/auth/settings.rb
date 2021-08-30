require 'omniauth'

module OIDC
  module Auth
    module Settings
      def base_settings
        # Support only third-parties that are discoverable.
        {
          client_options: {
            redirect_uri: "https://#{Rails.configuration.default_host}/users/auth/oidc/callback"
          },
          discovery: true,
          response_mode: :form_post,
          response_type: :id_token,
          scope: [:openid, :profile]
        }
      end

      def provider_settings(provider)
        raise 'Not an OIDC provider.' unless provider.is_a?(Provider::Oidc)

        {
          client_options: {
            identifier: provider.client_id
          },
          issuer: provider.issuer
        }
      end
    end
  end
end
