require 'omniauth'

module LTI
  module Auth
    module Settings
      def base_settings
        # This configuration is tailored according to the LTI specification.
        # To support other OpenID providers, simply move certain properties
        # from this method to the for_provider method below, to make them
        # provider-specific.
        {
            client_options: {
                redirect_uri: "https://#{Rails.configuration.default_host}/users/auth/lti/callback"
            },
            discovery: false,
            prompt: :none,
            response_mode: :form_post,
            response_type: :id_token,
            scope: [:openid]
        }
      end

      def provider_settings(provider)
        raise 'Not an LTI provider.' unless provider.is_a?(Provider::Lti)

        {
            client_options: {
                authorization_endpoint: provider.authorization_uri,
                jwks_uri: provider.jwks_uri,
                identifier: provider.client_id
            },
            issuer: provider.issuer
        }
      end
    end
  end
end
