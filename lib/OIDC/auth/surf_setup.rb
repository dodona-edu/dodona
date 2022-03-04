module OIDC
  module Auth
    module OmniAuth
      class SurfSetup < OIDC::Auth::OmniAuth::Setup
        def configure
          {
            discovery: true,
            client_auth_method: :basic,
            scope: [:openid],
            client_options: {
              host: 'connect.test.surfconext.nl',
              authorization_endpoint: '/oidc/authorize',
              token_endpoint: '/oidc/token',
              userinfo_endpoint: '/oidc/userinfo',
              jwks_uri: '/oidc/certs',
              identifier: Rails.application.credentials.surf_client_id || 'dodona.localhost',
              secret: Rails.application.credentials.surf_client_secret,
              redirect_uri: "https://naos.ugent.be/users/auth/surf/callback"
            },
            issuer: 'https://connect.test.surfconext.nl/oidc/'
          }
        end
      end
    end
  end
end
