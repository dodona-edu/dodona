require_relative '../client.rb'
require 'openid_connect'
require 'openid_connect/response_object'

# This strategy enables OIDC to be used by Dodona.
module OmniAuth
  module Strategies
    class Surf < OmniAuth::Strategies::OpenIDConnect
      include Rails.application.routes.url_helpers
      option :name, 'surf'

      # def client
      #   @client ||= ::OIDC::Client.new(client_options.merge(audience:'https://connect.test.surfconext.nl/oidc/token'))
      # end
    end
  end
end

OmniAuth.config.add_camelization 'surf', 'Surf'
