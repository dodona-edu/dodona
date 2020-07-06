require_relative '../../lib/SAML/metadata.rb'

# TODO: This controller has been copied from the previous SAML gem,
#      https://raw.githubusercontent.com/apokalipto/devise_saml_authenticatable/,
#      and currently exists for compatibility reasons. This should be removed
#      when refactoring the authentication mechanism.

class SamlSessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, raise: false

  def metadata
    render xml: OmniAuth::Strategies::SAML::Metadata.generate
  end
end
