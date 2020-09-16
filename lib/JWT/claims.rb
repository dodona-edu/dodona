module JWT::Claims
  # Reserved claims.
  AUDIENCE = 'aud'.freeze
  EXPIRATION = 'exp'.freeze
  ISSUER = 'iss'.freeze
  ISSUED_AT = 'iat'.freeze
  SUBJECT = 'sub'.freeze

  # OpenID claims.
  module OpenId
    AUTHORIZED_PARTY = 'azp'.freeze
    NONCE = 'nonce'.freeze

    EMAIL = 'email'.freeze

    FAMILY_NAME = 'family_name'.freeze
    GIVEN_NAME = 'given_name'.freeze
    NAME = 'name'.freeze
  end
end
