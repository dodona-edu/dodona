require 'omniauth'

module OmniAuth
  module Strategies
    class SAML
      include OmniAuth::Strategy

      def self.inherited(subclass)
        OmniAuth::Strategy.included(subclass)
      end

      # User requests to sign in with SAML.
      def request_phase
        # Build a new request.
        saml_auth_request = OneLogin::RubySaml::Authrequest.new

        # Amend the settings.
        with_settings do |settings|
          # Redirect the user to the federated sign-in page.
          redirect saml_auth_request.create(settings)
        end
      end

      def other_phase
        p "otter fase"
        p request_path
        call_app!
      end

      private

      def with_settings
        yield OneLogin::RubySaml::Settings.new options
      end
    end
  end
end

OmniAuth.config.add_camelization 'saml', 'SAML'
