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
        # This logic was added specifically for Vlaamse Overheid. By default,
        # the audience will be set to the token endpoint (which is compliant to
        # the OIDC specification). However, Vlaamse Overheid wants this to be
        # equal to the issuer.
        #
        # Token endpoint: https://authenticatie-ti.vlaanderen.be/op/v1/token.
        # Vlaamse Overheid wants: https://authenticatie-ti.vlaanderen.be/op.
        @client ||= ::OIDC::Client.new(client_options.merge(audience: options.issuer))
      end

      private

      def user_info
        return @user_info if @user_info

        # Set the email address alias. This is specific to Vlaamse Overheid.
        decoded = decode_id_token(access_token.id_token).raw_attributes
        decoded["email"] = decoded["vo_email"]
        @user_info = ::OpenIDConnect::ResponseObject::UserInfo.new(decoded)
      end
    end
  end
end

OmniAuth.config.add_camelization 'oidc', 'OIDC'
