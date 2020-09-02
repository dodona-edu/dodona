module LTI::Messages::Types
  class DeepLinkingResponse
    class LtiResourceLink
      # Type name.
      TYPE = 'ltiResourceLink'.freeze

      attr_accessor :title
      attr_accessor :url

      def initialize(title, url)
        @title = title
        @url = url
      end

      def as_json
        {
            title: @title,
            type: TYPE,
            url: @url
        }
      end
    end

    # Type name.
    TYPE = 'LtiDeepLinkingResponse'.freeze

    # Attributes.
    attr_accessor :items

    def initialize(provider)
      @items = []
      @provider = provider
    end

    def as_json
      base = {
          aud: @provider.issuer,
          iss: @provider.client_id
      }
      base[LTI::Messages::Claims::DEEP_LINKING_CONTENT_ITEMS] = @items.map(&:as_json)
      base[LTI::Messages::Claims::DEEP_LINKING_DATA] = 'Brightspace'
      base["https://purl.imsglobal.org/spec/lti/claim/deployment_id"] = 'c6899818-7062-44d1-b377-5a08097daeb3'
      base[LTI::Messages::Claims::MESSAGE_TYPE] = TYPE
      base[LTI::Messages::Claims::VERSION] = "1.3.0"
      base
    end
  end
end
