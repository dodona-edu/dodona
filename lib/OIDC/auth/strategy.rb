require_relative '../client.rb'
require 'openid_connect'
require 'openid_connect/response_object'

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
        return @user_info if @user_info

        @user_info = ::OpenIDConnect::ResponseObject::UserInfo.new(decode_id_token(access_token.id_token).raw_attributes)
      end
    end
  end
end

OmniAuth.config.add_camelization 'oidc', 'OIDC'
