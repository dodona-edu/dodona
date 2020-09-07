module LTI::Messages
  module Claims
    # Common & launch request.
    MESSAGE_TYPE = 'https://purl.imsglobal.org/spec/lti/claim/message_type'.freeze
    TARGET_LINK_URI = 'https://purl.imsglobal.org/spec/lti/claim/target_link_uri'.freeze
    VERSION = 'https://purl.imsglobal.org/spec/lti/claim/version'.freeze
    DEPLOYMENT_ID = 'https://purl.imsglobal.org/spec/lti/claim/deployment_id'.freeze
    RESOURCE_LINK = 'https://purl.imsglobal.org/spec/lti/claim/resource_link'.freeze
    LAUNCH_PRESENTATION = 'https://purl.imsglobal.org/spec/lti/claim/launch_presentation'.freeze

    # Deep Linking.
    DEEP_LINKING_CONTENT_ITEMS = 'https://purl.imsglobal.org/spec/lti-dl/claim/content_items'.freeze
    DEEP_LINKING_DATA = 'https://purl.imsglobal.org/spec/lti-dl/claim/data'.freeze
    DEEP_LINKING_SETTINGS = 'https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings'.freeze
    DEEP_LINKING_MESSAGE = 'https://purl.imsglobal.org/spec/lti-dl/claim/msg'.freeze
  end
end
