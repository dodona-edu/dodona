require_relative '../../../lib/SAML/metadata'

class Auth::SamlController < ApplicationController
  def metadata
    render xml: OmniAuth::Strategies::SAML::Metadata.generate(false, request.host)
  end
end
