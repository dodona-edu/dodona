module Surf
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
            client_options: {
              host: 'connect.surfconext.nl',
              identifier: Rails.application.credentials.surf_client_id,
              secret: Rails.application.credentials.surf_client_secret,
              redirect_uri: "https://#{@env['HTTP_HOST']}/users/auth/surf/callback"
            },
            issuer: 'https://connect.surfconext.nl'
          }
        end
      end
    end
  end
end
