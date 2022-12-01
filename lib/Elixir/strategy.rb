require 'openid_connect'
require 'openid_connect/response_object'

module OmniAuth
  module Strategies
    class Elixir < OmniAuth::Strategies::OpenIDConnect
      option :name, 'elixir'

      info do
        {
          # Elixir AAI does not provide a unique organisation, but instead offers a list of organisations
          # This list also changes over time, with organisations being removed 1 year after last login
          # This is unusable for us, so we group them all in a single organisation
          institution: "elixir",
        }
      end
    end
  end
end
