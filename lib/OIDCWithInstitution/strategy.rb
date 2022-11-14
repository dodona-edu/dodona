require 'openid_connect'
require 'openid_connect/response_object'

# This strategy enables Surf and Elixir to be used by Dodona.
# It adds a small change to the default open id connect, introducing the user institution
module OmniAuth
  module Strategies
    class OidcWithInstitution < OmniAuth::Strategies::OpenIDConnect
      option :name, :oidc_with_institution

      info do
        {
          institution: user_info.raw_attributes["schac_home_organization"],
        }
      end
    end
  end
end
