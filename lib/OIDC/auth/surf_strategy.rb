require_relative '../client.rb'
require 'openid_connect'
require 'openid_connect/response_object'

# This strategy enables OIDC to be used by Dodona.
module OmniAuth
  module Strategies
    class Surf < OmniAuth::Strategies::OpenIDConnect
      include Rails.application.routes.url_helpers
      option :name, 'surf'


      info do
        {
          institution: user_info.raw_info.schac_home_organization,
        }
      end
    end
  end
end
Rack::OAuth2.debug!
Rack::OAuth2.logger = Rails.logger
OmniAuth.config.add_camelization 'surf', 'Surf'
