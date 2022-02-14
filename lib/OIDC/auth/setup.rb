module OIDC
  module Auth
    module OmniAuth
      class Setup
        include OIDC::Auth::Settings

        def self.call(env)
          new(env).setup
        end

        def initialize(env)
          @env = env
        end

        def setup
          @env['omniauth.params'] ||= {}
          @env['omniauth.strategy'].options.merge!(base_settings(@env['HTTP_HOST']))
          @env['omniauth.strategy'].options.merge!(configure)
        end

        private

        def configure
          # Obtain the openid parameters for the provider.
          _provider = provider
          return failure! if _provider.blank?

          provider_settings(_provider)
        end

        def failure!
          raise "Invalid or unknown OIDC provider."
        end

        def params
          @params ||= Rack::Request.new(@env).params.symbolize_keys
        end

        def provider
          # Get the provider from the provider parameter.
          return Provider::Oidc.find_by(id: params[:provider]) if params[:provider].present?

          # Get the provider from the issuer parameter.
          return Provider::Oidc.find_by(issuer: params[:iss]) if params[:iss].present?

          # Get the provider from the state parameter.
          return Provider::Oidc.find_by(id: provider_from_state) if provider_from_state.present?

          # If there is a JWT available, we can parse that to find the issuer.
          return nil if params[:id_token].blank?

          # Parse the JWT token.
          jwt_token = JSON::JWT.decode params[:id_token], :skip_verification
          Provider::Oidc.find_by(issuer: jwt_token[:iss])
        end

        def provider_from_state
          # If there is no state, we will not find anything.
          return nil if params[:state].blank?

          # Attempt to split the state.
          state = params[:state].split("-", 2)
          return nil unless state.count == 2

          # Attempt to parse the id as an integer.
          parsed = state[0].to_i
          parsed > 0 ? parsed : nil
        end
      end
    end
  end
end
