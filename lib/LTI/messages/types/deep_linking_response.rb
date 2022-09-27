require_relative '../../tokens.rb'

module LTI::Messages::Types
  class DeepLinkingResponse < LTI::Tokens::ToolJwt
    class LtiResourceLink
      # Type name.
      TYPE = 'ltiResourceLink'.freeze

      attr_accessor :title
      attr_accessor :url

      def initialize(title, url)
        Rails.logger.info "=====================================#{self.class}##{__method__}"
        @title = title
        @url = url
      end

      def as_json(options = nil)
        Rails.logger.info "=====================================#{self.class}##{__method__}"
        {
            title: @title,
            type: TYPE,
            url: @url
        }
      end
    end

    # Type name.
    TYPE = 'LtiDeepLinkingResponse'.freeze

    attr_accessor :data
    attr_accessor :items
    attr_accessor :message

    def initialize(request)
      Rails.logger.info "=====================================#{self.class}##{__method__}"
      super(request)
      @data = request.data
      @items = []
    end

    def as_json(options = nil)
      Rails.logger.info "=====================================#{self.class}##{__method__}"
      base = super(options)
      base[LTI::Messages::Claims::DEEP_LINKING_DATA] = data if data.present?
      base[LTI::Messages::Claims::DEEP_LINKING_MESSAGE] = message if message.present?
      base[LTI::Messages::Claims::MESSAGE_TYPE] = TYPE
      base[LTI::Messages::Claims::VERSION] = "1.3.0"
      base[LTI::Messages::Claims::DEEP_LINKING_CONTENT_ITEMS] = items.as_json(options)
      base
    end
  end
end
