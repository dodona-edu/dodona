module LTI::Messages::Types

  # Basic JWT token.
  class JwtToken
    # Required
    attr_accessor :issuer
    attr_accessor :audience
    attr_accessor :expiration
    attr_accessor :issued_at
    attr_accessor :nonce
    # Optional
    attr_accessor :authorized_party

    def as_json(options=nil)
      base = {}
      base[LTI::Messages::Claims::OPENID_ISSUER] = @issuer
      base[LTI::Messages::Claims::OPENID_EXPIRATION] = @expiration
      base[LTI::Messages::Claims::OPENID_AUDIENCE] = @audience
      base[LTI::Messages::Claims::OPENID_ISSUED_AT] = @issued_at
      base[LTI::Messages::Claims::OPENID_NONCE] = @nonce
      base[LTI::Messages::Claims::OPENID_AUTHORIZED_PARTY] = @authorized_party unless @authorized_party.nil?
      base
    end
  end

  # The ID token, as defined by section 5.1.2 of the IMS Security Framework 1.0.
  # This is a Platform-originating message, meaning LMS send this to us.
  # The user related claims originate from section 5.3.6 of IMS 1.3, but are included here
  # since they are also OpenID claims.
  class IdToken < JwtToken
    # User information
    attr_reader :subject
    attr_reader :given_name
    attr_reader :family_name
    attr_reader :name
    attr_reader :email

    def initialize(token_body)
      @issuer = token_body[LTI::Messages::Claims::OPENID_ISSUER]
      @audience = token_body[LTI::Messages::Claims::OPENID_AUDIENCE]
      @expiration = token_body[LTI::Messages::Claims::OPENID_EXPIRATION]
      @issued_at = token_body[LTI::Messages::Claims::OPENID_ISSUED_AT]
      @nonce = token_body[LTI::Messages::Claims::OPENID_NONCE]
      @authorized_party = token_body[LTI::Messages::Claims::OPENID_AUTHORIZED_PARTY]
      @subject = token_body[LTI::Messages::Claims::OPENID_SUBJECT]
      @given_name = token_body[LTI::Messages::Claims::OPENID_GIVEN_NAME]
      @family_name = token_body[LTI::Messages::Claims::OPENID_FAMILY_NAME]
      @name = token_body[LTI::Messages::Claims::OPENID_NAME]
      @email = token_body[LTI::Messages::Claims::OPENID_EMAIL]
    end

    def as_json(options=nil)
      base = super(options)
      base[LTI::Messages::Claims::OPENID_SUBJECT] = @subject unless @subject.nil?
      base[LTI::Messages::Claims::OPENID_GIVEN_NAME] = @given_name unless @given_name.nil?
      base[LTI::Messages::Claims::OPENID_FAMILY_NAME] = @family_name unless @family_name.nil?
      base[LTI::Messages::Claims::OPENID_NAME] = @name unless @name.nil?
      base[LTI::Messages::Claims::OPENID_EMAIL] = @email unless @email.nil?
      base
    end
  end

  # The Tool JWT, as defined by section 5.2.2 of the IMS Security Framework 1.0.
  # This is a Tool-originating message, meaning we send it to LMS.
  # The exp & iat are normally set by the LTI::JWT module.
  class ToolJwt < JwtToken
    # Initialise the Tool JWT
    def initialize(old_token, provider)
      @nonce = old_token.nonce
      @audience = provider.issuer
      @issuer = provider.client_id
    end
  end
end
