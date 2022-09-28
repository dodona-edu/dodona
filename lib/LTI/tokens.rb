require_relative '../JWT/token.rb'

module LTI::Tokens
  class LTIToken < JWT::JwtToken
    # Platform information.
    attr_reader :deployment_id

    def initialize(attributes)
      super(attributes)
      @deployment_id = attributes[LTI::Messages::Claims::DEPLOYMENT_ID]
    end

    def as_json(options = nil)
      base = super(options)
      base[LTI::Messages::Claims::DEPLOYMENT_ID] = deployment_id
      base
    end
  end

  # The ID token, as defined by section 5.1.2 of the IMS Security Framework 1.0.
  # This is a Platform-originating message, meaning LMS send this to us.
  # The user related claims originate from section 5.3.6 of IMS 1.3, but are included here
  # since they are also OpenID claims.
  class IdToken < LTIToken
    # User information.
    attr_reader :given_name
    attr_reader :family_name
    attr_reader :name

    attr_reader :email

    # Platform information.
    attr_reader :deployment_id

    def initialize(attributes)
      super(attributes)
      @email = attributes[JWT::Claims::OpenId::EMAIL]
      @family_name = attributes[JWT::Claims::OpenId::FAMILY_NAME]
      @given_name = attributes[JWT::Claims::OpenId::GIVEN_NAME]
      @name = attributes[JWT::Claims::OpenId::NAME]
    end

    def as_json(options = nil)
      base = super(options)
      base[JWT::Claims::OpenId::EMAIL] = email if email.present?
      base[JWT::Claims::OpenId::FAMILY_NAME] = family_name if family_name.present?
      base[JWT::Claims::OpenId::GIVEN_NAME] = given_name if given_name.present?
      base[JWT::Claims::OpenId::NAME] = name if name.present?
      base
    end
  end

  # The Tool JWT, as defined by section 5.2.2 of the IMS Security Framework 1.0.
  # This is a Tool-originating message, meaning we send it to LMS.
  class ToolJwt < LTIToken
    # @param [LTI::Tokens::IdToken] request_token: the request this response is for
    def initialize(request_token)
      base = {}

      # Audience of the request is the issuer of the response.
      base[JWT::Claims::ISSUER] = request_token.audience

      # Issuer of the request is the audience of the response.
      base[JWT::Claims::AUDIENCE] = request_token.issuer

      # Set the issued and expiration timestamps.
      base[JWT::Claims::EXPIRATION] = Time.now.to_i + 600
      base[JWT::Claims::ISSUED_AT] = Time.now.to_i

      # Nonce must match the request.
      base[JWT::Claims::OpenId::NONCE] = request_token.nonce

      # Deployment id must match the request.
      base[LTI::Messages::Claims::DEPLOYMENT_ID] = request_token.deployment_id

      # Set optional values.
      if request_token.subject.present?
        base[JWT::Claims::SUBJECT] = request_token.subject
      end

      # Build the base token.
      super(base)
    end
  end
end
