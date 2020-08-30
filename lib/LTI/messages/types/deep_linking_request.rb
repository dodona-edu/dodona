module LTI::Messages::Types
  class DeepLinkingRequest
    # Type name.
    TYPE = 'LtiDeepLinkingRequest'.freeze

    # Settings.
    SETTING_RETURN_URL = 'deep_link_return_url'.freeze

    attr_reader :return_url

    def initialize(token_body)
      settings = token_body[LTI::Messages::Claims::DEEP_LINKING_SETTINGS]
      @return_url = settings[SETTING_RETURN_URL]
    end
  end
end
