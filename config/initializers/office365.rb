require 'omniauth-oauth2'
require 'jwt'

module OmniAuth
  module Strategies
    class Office365 < OmniAuth::Strategies::OAuth2
      option :provider_ignores_state, true

      # strategy name
      option :name, 'office365'

      option :client_options,
             site: 'https://login.microsoftonline.com/',
             authorize_url: '/common/oauth2/v2.0/authorize',
             token_url: '/common/oauth2/v2.0/token'

      DEFAULT_SCOPE = "openid email profile"

      def authorize_params
        super.tap do |params|
          %w[display scope auth_type].each do |v|
            if request.params[v]
              params[v.to_sym] = request.params[v]
            end
          end

          params[:scope] ||= DEFAULT_SCOPE
          params[:prompt] = 'select_account'
        end
      end

      # These are called after authentication has succeeded.
      uid { raw_info['oid'] }

      info do
        {
            username: username,
            first_name: raw_info['name'].split(' ').first,
            last_name: raw_info['name'].split(' ').drop(1).join(' '),
            email: raw_info['email'],
            institution: raw_info['tid']
        }
      end

      extra do
        {
            'raw_info' => raw_info
        }
      end

      def username
        raw_info['email'].split('@').first
      end

      def decoded_token
        JWT.decode(access_token.params['id_token'], nil, false).first
      end

      def raw_info
        @raw_info ||= decoded_token
      end

      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end
