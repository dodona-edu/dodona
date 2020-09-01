module LTI::Messages
  module Claims
    # Common.
    MESSAGE_TYPE = 'https://purl.imsglobal.org/spec/lti/claim/message_type'.freeze
    TARGET_LINK_URI = 'https://purl.imsglobal.org/spec/lti/claim/target_link_uri'.freeze
    VERSION = 'https://purl.imsglobal.org/spec/lti/claim/version'.freeze

    # Deep Linking.
    DEEP_LINKING_CONTENT_ITEMS = 'https://purl.imsglobal.org/spec/lti-dl/claim/content_items'.freeze
    DEEP_LINKING_DATA = 'https://purl.imsglobal.org/spec/lti-dl/claim/data'.freeze
    DEEP_LINKING_SETTINGS = 'https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings'.freeze
  end
end
