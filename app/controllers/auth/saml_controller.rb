require_relative '../../../lib/SAML/metadata.rb'

class Auth::SamlController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def metadata
    render xml: OmniAuth::Strategies::SAML::Metadata.generate
  end
end
