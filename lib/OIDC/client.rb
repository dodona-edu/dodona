require "json/jwt"
require "rack/oauth2/client/grant/authorization_code"

module OIDC
  class Client < OpenIDConnect::Client
    attr_optional :audience

    def authorization_code=(code)
      # Calculate the client assertion.
      assertion = JSON::JWT.new(
        iss: identifier,
        sub: identifier,
        aud: audience,
        jti: SecureRandom.hex(16),
        iat: Time.now,
        exp: 3.minutes.from_now
      ).sign(private_key || secret).to_s

      # Set the grant.
      @grant = JWTAuthorizationCodeGrant.new(
        client_assertion: assertion,
        code: code,
        redirect_uri: self.redirect_uri
      )
    end
  end

  class JWTAuthorizationCodeGrant < Rack::OAuth2::Client::Grant::AuthorizationCode
    attr_required :client_assertion

    def grant_type
      "authorization_code"
    end
  end
end
