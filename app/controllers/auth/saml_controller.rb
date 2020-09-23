require_relative '../../../lib/SAML/metadata'

class Auth::SamlController < ApplicationController
  def metadata
    render xml: OmniAuth::Strategies::SAML::Metadata.generate
  end
end
