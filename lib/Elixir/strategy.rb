require 'openid_connect'
require 'openid_connect/response_object'

# This strategy enables Surf to be used by Dodona.
# It adds a smal change to the default open id connect, introducing the user institution
module OmniAuth
  module Strategies
    class Elixir < OmniAuth::Strategies::OpenIDConnect
      option :name, 'elixir'

      info do
        {
          institution: user_info.raw_attributes["schac_home_organization"],
        }
      end

      extra do
        {
          'user_info' => user_info,
        }
      end
    end
  end
end
