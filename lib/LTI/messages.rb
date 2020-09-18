module LTI
  module Messages
    require_relative 'messages/claims.rb'
    require_relative 'messages/types.rb'

    def parse_message(token, provider_id)
      return nil if token.nil? or provider_id.nil?

      # Get the provider of the token.
      provider = Provider::Lti.find(provider_id)
      return nil if provider.nil?

      # Get the JWK set and parse the token.
      jwks = parse_jwks_uri(provider.jwks_uri)
      parsed_token = JSON::JWT.decode(token, jwks)

      # Obtain the type and delegate to the corresponding handler.
      message_type = parsed_token[::LTI::Messages::Claims::MESSAGE_TYPE]
      if message_type == ::LTI::Messages::Types::DeepLinkingRequest::TYPE
        return ::LTI::Messages::Types::DeepLinkingRequest.new(parsed_token)
      elsif message_type == ::LTI::Messages::Types::ResourceLaunchRequest::TYPE
        return ::LTI::Messages::Types::ResourceLaunchRequest.new(parsed_token)
      end

      # Not implemented / invalid type.
      raise format('Unsupported message type: %<type>s', type: message_type)

    end
  end
end
