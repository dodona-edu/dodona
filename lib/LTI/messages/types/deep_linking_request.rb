module LTI::Messages::Types
  class DeepLinkingRequest < ResourceLaunchRequest
    # Type name.
    TYPE = 'LtiDeepLinkingRequest'.freeze

    # Claims in the deep link settings.
    RETURN_URL = 'deep_link_return_url'.freeze
    ACCEPT_TYPES = 'accept_types'.freeze
    ACCEPT_PRESENTATION_DOCUMENT_TARGETS = 'accept_presentation_document_targets'.freeze
    ACCEPT_MEDIA_TYPES = 'accept_media_types'.freeze
    ACCEPT_MULTIPLE = 'accept_multiple'.freeze
    AUTO_CREATE = 'auto_create'.freeze
    TITLE = 'title'.freeze
    TEXT = 'text'.freeze
    DATA = 'data'.freeze

    attr_reader :return_url
    attr_reader :accept_types
    attr_reader :accept_presentation_document_targets
    attr_reader :accept_media_types
    attr_reader :accept_multiple
    attr_reader :auto_create
    attr_reader :title
    attr_reader :text
    attr_reader :data

    def initialize(token_body)
      super(token_body)
      settings = token_body[LTI::Messages::Claims::DEEP_LINKING_SETTINGS]
      @return_url = settings[RETURN_URL]
      @accept_types = settings[ACCEPT_TYPES]
      @accept_presentation_document_targets = settings[ACCEPT_PRESENTATION_DOCUMENT_TARGETS]
      @accept_media_types = settings[ACCEPT_MEDIA_TYPES]
      @accept_multiple = settings[ACCEPT_MULTIPLE]
      @auto_create = settings[AUTO_CREATE]
      @title = settings[TITLE]
      @text = settings[TEXT]
      @data = settings[DATA]
    end

    def as_json(options=nil)
      base = super(options)
      settings = {}
      settings[RETURN_URL] = @return_url
      settings[ACCEPT_TYPES] = @accept_types
      settings[ACCEPT_PRESENTATION_DOCUMENT_TARGETS] = @accept_presentation_document_targets
      settings[ACCEPT_MEDIA_TYPES] = @accept_media_types.nil?
      settings[ACCEPT_MULTIPLE] = @accept_multiple.nil?
      settings[AUTO_CREATE] = @auto_create unless @auto_create.nil?
      settings[TITLE] = @title
      settings[TEXT] = @text
      settings[DATA] = @data
      base[LTI::Messages::Claims::DEEP_LINKING_SETTINGS] = settings
      base
    end
  end
end
