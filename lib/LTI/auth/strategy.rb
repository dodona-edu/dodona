require_relative '../jwk.rb'
require_relative '../messages/claims.rb'
require_relative '../messages/types.rb'
require 'openid_connect'

# This strategy augments the existing oidc strategy for Dodona.
module OmniAuth
  module Strategies
    class LTI < OmniAuth::Strategies::OpenIDConnect
      include ::LTI::JWK
      include Rails.application.routes.url_helpers

      option :name, 'lti'

      def initialize(app, *args, &block)
        # Disable validation phase for lti authentication requests
        # See https://github.com/dodona-edu/dodona/pull/4029
        OmniAuth.config.request_validation_phase { }
        super
      end

      def key_or_secret
        Rails.logger.info "=====================================#{self.class}##{__method__}"
        parse_jwks_uri(options.client_options.jwks_uri)
      end

      def callback_phase
        Rails.logger.info "=====================================#{self.class}##{__method__}"
        begin
          super
        rescue => e
          # Error handling.
          fail!(:invalid_response, $!)
        end
      end

      def id_token_callback_phase
        Rails.logger.info "=====================================#{self.class}##{__method__}"
        # Parse the JWT to obtain the raw response.
        jwt_token = params.symbolize_keys[:id_token]
        raw_info = decode_id_token(jwt_token).raw_attributes

        # Set the redirect url.
        target_link_uri = raw_info[::LTI::Messages::Claims::TARGET_LINK_URI]

        # Ufora does not use the correct content selection endpoint, so
        # depending on the message type, we force this.
        if raw_info[::LTI::Messages::Claims::MESSAGE_TYPE] == ::LTI::Messages::Types::DeepLinkingRequest::TYPE
          target_link_uri = content_selection_path
        end

        # Configure the info hashes.
        provider = Provider::Lti.find_by(issuer: raw_info[:iss])
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
                provider_id: provider&.id,
                redirect_params: {
                    id_token: jwt_token,
                    provider_id: provider&.id
                },
                target: target_link_uri
            }
        )

        call_app!
      end
    end
  end
end

OmniAuth.config.add_camelization 'lti', 'LTI'
