module LTI::Messages
  module Claims
    # OpenID
    OPENID_ISSUER = 'iss'.freeze
    OPENID_AUDIENCE = 'aud'.freeze
    OPENID_EXPIRATION = 'exp'.freeze
    OPENID_ISSUED_AT = 'iat'.freeze
    OPENID_NONCE = 'nonce'.freeze
    OPENID_AUTHORIZED_PARTY = 'azp'.freeze
    OPENID_SUBJECT = 'sub'.freeze
    OPENID_GIVEN_NAME = 'given_name'.freeze
    OPENID_FAMILY_NAME = 'family_name'.freeze
    OPENID_NAME = 'name'.freeze
    OPENID_EMAIL = 'email'.freeze

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
