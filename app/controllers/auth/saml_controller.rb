require_relative '../../../lib/SAML/metadata.rb'

class Auth::SamlController < ApplicationController
  def metadata
    render xml: OmniAuth::Strategies::SAML::Metadata.generate
  end
end
