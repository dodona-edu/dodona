require_relative '../jwk.rb'
require_relative '../messages/claims.rb'
require 'openid_connect'

# This strategy augments the existing oidc strategy for Dodona.
module OmniAuth
  module Strategies
    class LTI < OmniAuth::Strategies::OpenIDConnect
      include ::LTI::JWK

      option :name, 'lti'

      def key_or_secret
        parse_jwks_uri(options.client_options.jwks_uri)
      end

      def callback_phase
        begin
          super
        rescue
          # Error handling.
          fail!(:invalid_response, $!)
        end
      end

      def id_token_callback_phase
        # Parse the JWT to obtain the raw response.
        jwt_token = params.symbolize_keys[:id_token]
        raw_info = decode_id_token(jwt_token).raw_attributes

        # Configure the info hashes.
        env['omniauth.auth'] = AuthHash.new(
            provider: name,
            uid: raw_info[:sub],
            info: {
                username: raw_info[:sub],
                first_name: raw_info[:given_name],
                last_name: raw_info[:family_name],
                email: raw_info[:email]
            },
            extra: {
                provider: Provider::Lti.find_by(issuer: raw_info[:iss]),
                redirect_params: {
                    id_token: jwt_token,
                    issuer: raw_info[:iss]
                },
                target: raw_info[::LTI::Messages::Claims::TARGET_LINK_URI]
            }
        )

        call_app!
      end
    end
  end
end

OmniAuth.config.add_camelization 'lti', 'LTI'
