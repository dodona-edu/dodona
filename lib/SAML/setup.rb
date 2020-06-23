require_relative 'settings.rb'

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
          @env['omniauth.strategy'].options.merge!(OmniAuth::Strategies::SAML::Settings.defaults)
          @env['omniauth.strategy'].options.merge!(configure)
        end

        private

        def configure
          # Obtain the id of the institution from the parameters.
          params = Rack::Request.new(@env).params.symbolize_keys
          id = params[:institution]
          return {} if id.blank?

          # Obtain the saml parameters for the institution.
          institution = Institution.find_by(id: id)
          return failure! if institution.blank?

          OmniAuth::Strategies::SAML::Settings.for_institution(institution)
        end

        def failure!
          # TODO redirect
          raise "Invalid institution."
        end
      end
    end
  end
end
