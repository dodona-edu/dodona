require_relative '../client.rb'
require 'openid_connect'

# This strategy enables OIDC to be used by Dodona.
module OmniAuth
  module Strategies
    class OIDC < OmniAuth::Strategies::OpenIDConnect
      include Rails.application.routes.url_helpers

      option :name, 'oidc'

      def client
        @client ||= ::OIDC::Client.new(client_options.merge(audience: options.issuer))
      end

      private

      def user_info
        decoded = decode_id_token(access_token.id_token)
        Rails.logger.info access_token.id_token
        Rails.logger.info decoded
        Rails.logger.info decoded.raw_attributes
        super
      end
    end
  end
end

OmniAuth.config.add_camelization 'oidc', 'OIDC'
