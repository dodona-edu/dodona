require_relative '../../../lib/SAML/metadata.rb'

class Auth::SamlController < ActionController::Base
  def metadata
    render xml: OmniAuth::Strategies::SAML::Metadata.generate
  end
end
