module LTI
  module Auth
    module OmniAuth
      class Setup
        include LTI::Auth::Settings

        def self.call(env)
          Rails.logger.info "=====================================#{self.class}##{__method__}"
          new(env).setup
        end

        def initialize(env)
          Rails.logger.info "=====================================#{self.class}##{__method__}"
          @env = env
        end

        def setup
          Rails.logger.info "=====================================#{self.class}##{__method__}"
          @env['omniauth.params'] ||= {}
          @env['omniauth.strategy'].options.merge!(base_settings(@env['HTTP_HOST']))
          @env['omniauth.strategy'].options.merge!(configure)
        end

        private

        def configure
          Rails.logger.info "=====================================#{self.class}##{__method__}"
          # Obtain the openid parameters for the provider.
          _provider = provider
          return failure! if _provider.blank?

          _provider_settings = provider_settings(_provider)
          _provider_settings.merge({
                                       extra_authorize_params: {
                                           lti_message_hint: params[:lti_message_hint]
                                       }
                                   })
        end

        def failure!
          Rails.logger.info "=====================================#{self.class}##{__method__}"
          raise "Invalid or unknown LTI provider."
        end

        def params
          Rails.logger.info "=====================================#{self.class}##{__method__}"
          @params ||= Rack::Request.new(@env).params.symbolize_keys
        end

        def provider
          Rails.logger.info "=====================================#{self.class}##{__method__}"
          # Get the provider from the provider parameter.
          return Provider::Lti.find_by(id: params[:provider]) if params[:provider].present?

          # Get the provider from the issuer parameter.
          return Provider::Lti.find_by(issuer: params[:iss]) if params[:iss].present?

          # If there is a JWT available, we can parse that to find the issuer.
          return nil if params[:id_token].blank?

          # Parse the JWT token.
          jwt_token = JSON::JWT.decode params[:id_token], :skip_verification
          Provider::Lti.find_by(issuer: jwt_token[:iss])
        end
      end
    end
  end
end
