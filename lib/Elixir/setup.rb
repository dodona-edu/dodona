module Elixir
  module Auth
    module OmniAuth
      class Setup
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

        private

        def configure
          {
            discovery: true,
            response_mode: :form_post,
            scope: [:openid, :email],
            client_options: {
              host: "https://login.elixir-czech.org/oidc/",
              identifier: Rails.application.credentials.elixir_client_id,
              secret: Rails.application.credentials.elixir_client_secret,
              redirect_uri: "https://#{@env['HTTP_HOST']}/users/auth/elixir/callback"
            },
            issuer: "https://login.elixir-czech.org/oidc/",
          }
        end
      end
    end
  end
end
