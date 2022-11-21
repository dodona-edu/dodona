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
          institution: "elixir",
        }
      end
    end
  end
end
