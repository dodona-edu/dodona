require_relative '../../../lib/SAML/metadata'

class Auth::SamlController < ApplicationController
  def metadata
    settings = OneLogin::RubySaml::Settings.new OmniAuth::Strategies::SAML::Settings.base(request.host)
    meta = OmniAuth::Strategies::SAML::Metadata.new
    render xml: meta.generate(settings, false)
  end
end
