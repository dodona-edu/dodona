require 'openid_connect'

# This strategy enables OIDC to be used by Dodona.
module OmniAuth
  module Strategies
    class OIDC < OmniAuth::Strategies::OpenIDConnect
      include Rails.application.routes.url_helpers

      option :name, 'oidc'
    end
  end
end

OmniAuth.config.add_camelization 'oidc', 'OIDC'
