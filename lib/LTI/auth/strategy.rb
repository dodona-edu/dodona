require_relative '../jwk.rb'
require_relative '../messages/claims.rb'
require 'openid_connect'

# This strategy augments the existing oidc strategy for Dodona.
module OmniAuth
  module Strategies
    class LTI < OmniAuth::Strategies::OpenIDConnect
      include ::LTI::JWK
      include Rails.application.routes.url_helpers

      option :name, 'lti'

      def request_call
        Rails.logger.info "=====================================#{self.class}##{__method__}"
        log :info, 'Request phase initiated.'
        Rails.logger.info "=====================================#{self.class}##{__method__} A"

        # store query params from the request url, extracted in the callback_phase
        session['omniauth.params'] = request.GET
        Rails.logger.info "=====================================#{self.class}##{__method__} B"
        OmniAuth.config.before_request_phase.call(env) if OmniAuth.config.before_request_phase
        Rails.logger.info "=====================================#{self.class}##{__method__} C"

        if options.form.respond_to?(:call)
          Rails.logger.info "=====================================#{self.class}##{__method__} D"
          log :info, 'Rendering form from supplied Rack endpoint.'
          Rails.logger.info "=====================================#{self.class}##{__method__} E"
          options.form.call(env)
        elsif options.form
          Rails.logger.info "=====================================#{self.class}##{__method__} F"
          log :info, 'Rendering form from underlying application.'
          Rails.logger.info "=====================================#{self.class}##{__method__} G"
          call_app!
        elsif !options.origin_param
          Rails.logger.info "=====================================#{self.class}##{__method__} H"
          request_phase
        else
          if request.params[options.origin_param]
            Rails.logger.info "=====================================#{self.class}##{__method__} I"
            env['rack.session']['omniauth.origin'] = request.params[options.origin_param]
          elsif env['HTTP_REFERER'] && !env['HTTP_REFERER'].match(/#{request_path}$/)
            Rails.logger.info "=====================================#{self.class}##{__method__} J"
            env['rack.session']['omniauth.origin'] = env['HTTP_REFERER']
          end
          Rails.logger.info "=====================================#{self.class}##{__method__} K"

          request_phase
        end
        Rails.logger.info "=====================================#{self.class}##{__method__} END"
      end

      def request_phase
        Rails.logger.info "=====================================#{self.class}##{__method__}"
        options.issuer = issuer if options.issuer.to_s.empty?
        Rails.logger.info "=====================================#{self.class}##{__method__} A"
        discover!
        Rails.logger.info "=====================================#{self.class}##{__method__} B"
        redirect authorize_uri
        Rails.logger.info "=====================================#{self.class}##{__method__} END"
      end



      def discover!
        Rails.logger.info "=====================================#{self.class}##{__method__}"
        return unless options.discovery
        Rails.logger.info "=====================================#{self.class}##{__method__} A"

        client_options.authorization_endpoint = config.authorization_endpoint
        Rails.logger.info "=====================================#{self.class}##{__method__} B"
        client_options.token_endpoint = config.token_endpoint
        Rails.logger.info "=====================================#{self.class}##{__method__} C"
        client_options.userinfo_endpoint = config.userinfo_endpoint
        Rails.logger.info "=====================================#{self.class}##{__method__} D"
        client_options.jwks_uri = config.jwks_uri
        Rails.logger.info "=====================================#{self.class}##{__method__} E"
        client_options.end_session_endpoint = config.end_session_endpoint if config.respond_to?(:end_session_endpoint)
        Rails.logger.info "=====================================#{self.class}##{__method__} END"
      end

      def authorize_uri
        Rails.logger.info "=====================================#{self.class}##{__method__}"
        client.redirect_uri = redirect_uri
        Rails.logger.info "=====================================#{self.class}##{__method__} A"
        opts = {
          response_type: options.response_type,
          response_mode: options.response_mode,
          scope: options.scope,
          state: new_state,
          login_hint: params['login_hint'],
          ui_locales: params['ui_locales'],
          claims_locales: params['claims_locales'],
          prompt: options.prompt,
          nonce: (new_nonce if options.send_nonce),
          hd: options.hd,
          acr_values: options.acr_values,
        }
        Rails.logger.info "=====================================#{self.class}##{__method__} B"

        opts.merge!(options.extra_authorize_params) unless options.extra_authorize_params.empty?

        Rails.logger.info "=====================================#{self.class}##{__method__} C"
        options.allow_authorize_params.each do |key|
          opts[key] = request.params[key.to_s] unless opts.key?(key)
        end
        Rails.logger.info "=====================================#{self.class}##{__method__} D"

        client.authorization_uri(opts.reject { |_k, v| v.nil? })
        Rails.logger.info "=====================================#{self.class}##{__method__} END"
      end

      def key_or_secret
        Rails.logger.info "=====================================#{self.class}##{__method__}"
        parse_jwks_uri(options.client_options.jwks_uri)
      end

      def callback_phase
        Rails.logger.info "=====================================#{self.class}##{__method__}"
        begin
          super
        rescue => e
          # Error handling.
          fail!(:invalid_response, $!)
        end
      end

      def id_token_callback_phase
        Rails.logger.info "=====================================#{self.class}##{__method__}"
        # Parse the JWT to obtain the raw response.
        jwt_token = params.symbolize_keys[:id_token]
        raw_info = decode_id_token(jwt_token).raw_attributes

        # Set the redirect url.
        target_link_uri = raw_info[::LTI::Messages::Claims::TARGET_LINK_URI]

        # Ufora does not use the correct content selection endpoint, so
        # depending on the message type, we force this.
        if raw_info[::LTI::Messages::Claims::MESSAGE_TYPE] == ::LTI::Messages::Types::DeepLinkingRequest::TYPE
          target_link_uri = content_selection_path
        end

        # Configure the info hashes.
        provider = Provider::Lti.find_by(issuer: raw_info[:iss])
        env['omniauth.auth'] = AuthHash.new(
            provider: name,
            uid: raw_info[:sub],
            info: {
                username: raw_info[:sub],
                first_name: raw_info[:given_name],
                last_name: raw_info[:family_name],
                email: raw_info[:email]
            },
            extra: {
                provider_id: provider&.id,
                redirect_params: {
                    id_token: jwt_token,
                    provider_id: provider&.id
                },
                target: target_link_uri
            }
        )

        call_app!
      end
    end
  end
end

OmniAuth.config.add_camelization 'lti', 'LTI'
