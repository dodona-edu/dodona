require_relative 'claims.rb'

module JWT
  # Basic JWT token.
  class JwtToken
    # Required fields.
    attr_accessor :audience
    attr_accessor :expiration
    attr_accessor :issuer
    attr_accessor :issued_at
    attr_accessor :nonce

    # Optional fields.
    attr_accessor :authorized_party
    attr_accessor :subject

    def initialize(attributes)
      @audience = attributes[JWT::Claims::AUDIENCE]
      @expiration = attributes[JWT::Claims::EXPIRATION]
      @issuer = attributes[JWT::Claims::ISSUER]
      @issued_at = attributes[JWT::Claims::ISSUED_AT]
      @nonce = attributes[JWT::Claims::OpenId::NONCE]

      if attributes[JWT::Claims::OpenId::AUTHORIZED_PARTY].present?
        @authorized_party = attributes[JWT::Claims::OpenId::AUTHORIZED_PARTY]
      end
      if attributes[JWT::Claims::SUBJECT].present?
        @subject = attributes[JWT::Claims::SUBJECT]
      end
    end

    def as_json(options = nil)
      base = {}
      base[JWT::Claims::AUDIENCE] = audience
      base[JWT::Claims::EXPIRATION] = expiration
      base[JWT::Claims::ISSUER] = issuer
      base[JWT::Claims::ISSUED_AT] = issued_at
      base[JWT::Claims::OpenId::NONCE] = nonce

      if authorized_party.present?
        base[JWT::Claims::OpenId::AUTHORIZED_PARTY] = authorized_party
      end
      if subject.present?
        base[JWT::Claims::SUBJECT] = subject
      end

      base
    end
  end
end
