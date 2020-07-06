require_relative 'settings.rb'

# Inspired by:
# https://madeintandem.com/blog/configuring-rails-app-single-sign-saml-multiple-providers/

module OmniAuth
  module Strategies
    class SAML
      class Setup
        def self.call(env)
          new(env).setup
        end

        def initialize(env)
          @env = env
        end

        def setup
          @env['omniauth.params'] ||= {}
          @env['omniauth.strategy'].options.merge!(OmniAuth::Strategies::SAML::Settings.base)
          @env['omniauth.strategy'].options.merge!(configure)
        end

        private

        def configure
          # Obtain the id of the provider from the parameters.
          params = Rack::Request.new(@env).params.symbolize_keys
          id = params[:provider]
          return {} if id.blank?

          # Obtain the saml parameters for the provider.
          provider = Provider::Saml.find_by(id: id)
          return failure! if provider.blank?

          OmniAuth::Strategies::SAML::Settings.for_provider(provider)
        end

        def failure!
          raise "Invalid provider."
        end
      end
    end
  end
end
