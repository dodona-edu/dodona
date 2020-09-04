module LTI::Messages::Types
  class DeepLinkingResponse < ToolJwt
    class LtiResourceLink
      # Type name.
      TYPE = 'ltiResourceLink'.freeze

      attr_accessor :title
      attr_accessor :url

      def initialize(title, url)
        @title = title
        @url = url
      end

      def as_json(options=nil)
        {
            title: @title,
            type: TYPE,
            url: @url
        }
      end
    end

    # Type name.
    TYPE = 'LtiDeepLinkingResponse'.freeze

    attr_accessor :deployment_id
    attr_accessor :data
    attr_accessor :items
    attr_accessor :message

    def initialize(previous_token, provider)
      super(previous_token, provider)
      @deployment_id = previous_token.deployment_id
      @data = previous_token.data
      @items = []
    end

    def as_json(options=nil)
      base = super
      base[LTI::Messages::Claims::DEPLOYMENT_ID] = @deployment_id
      base[LTI::Messages::Claims::DEEP_LINKING_DATA] = @data if @data.present?
      base[LTI::Messages::Claims::DEEP_LINKING_MESSAGE] = @message if @message.present?
      base[LTI::Messages::Claims::MESSAGE_TYPE] = TYPE
      base[LTI::Messages::Claims::VERSION] = "1.3.0"
      base[LTI::Messages::Claims::DEEP_LINKING_CONTENT_ITEMS] = @items.as_json(options)
      base
    end
  end
end
