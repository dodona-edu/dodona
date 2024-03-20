require_relative '../ent.rb'
require 'openid_connect'
require 'openid_connect/response_object'

# ACMIDM is an expension upon the OpenIDConnect Protocol
# Changes are applied to support the specific requirements of the flemish government
# This is used by both government officials and LeerID
module OmniAuth
  module Strategies
    class ACMIDM < OmniAuth::Strategies::OpenIDConnect
      include Rails.application.routes.url_helpers

      option :name, 'oidc'

      info do
        {
          # No org is provided for flemish government accounts, so we default to 'vlaamse-overheid'
          institution: user_info.raw_attributes['ov_orgcode'] || "vlaamse-overheid",
          institution_name: user_info.raw_attributes['ov_orgnaam'] || "Vlaamse Overheid",
          email: user_info.raw_attributes['vo_email'] # this will be nil for leerid accounts
        }
      end

      def client
        # This logic was added specifically for Vlaamse Overheid. By default,
        # the audience will be set to the token endpoint (which is compliant to
        # the OIDC specification). However, Vlaamse Overheid wants this to be
        # equal to the issuer.
        #
        # Token endpoint: https://authenticatie-ti.vlaanderen.be/op/v1/token.
        # Vlaamse Overheid wants: https://authenticatie-ti.vlaanderen.be/op.
        @client ||= ::ACMIDM::Client.new(client_options.merge(audience: options.issuer))
      end

      def uid
        # Leerid accounts do not provide a sub, instead they provide 'ov_account_uuid', 'ov_leerid_uuid' and 'ov_historiek_account_uuid'
        # We use 'ov_account_uuid' as it is always present
        # It is important to note that 'ov_account_uuid' could change over time, but this should only happen in edge cases: eg. after merging accounts from foreign students
        # Should we notice that this causes too much trouble, more complex logic should be implemented
        # Probably in omniauth_callbacks_controller `find_identity_by_uid`
        super || user_info.raw_attributes['ov_account_uuid']
      end
    end
  end
end

