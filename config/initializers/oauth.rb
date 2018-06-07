require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Oauth < OmniAuth::Strategies::OAuth2
      option :provider_ignores_state, true

      # strategy name
      option :name, 'oauth'

      # This is where you pass the options you would pass when
      # initializing your consumer from the OAuth gem.
      option :client_options,
             site:              'https://slow.smartschool.be/',
             authorize_url:     '/OAuth?scope=fulluserinfo',
             token_url:         '/OAuth/index/token'

      # These are called after authentication has succeeded.
      uid { raw_info['username'] }

      info do
        {
          username:     raw_info['username'],
          first_name:   raw_info['name'],
          last_name:    raw_info['surname'],
          email:        raw_info['email'],
          institution:  raw_info['platform']
        }
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.get('/Api/V1/fulluserinfo').parsed
      end

      def callback_url
        # TODO: change back
        # fullhost + script + callback_path
        'http://localhost:3000/users/auth/oauth2/callback'
      end
    end
  end
end
