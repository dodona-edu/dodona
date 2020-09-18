require_relative '../../tokens.rb'

module LTI::Messages::Types
  # Defined in section 5 of IMS version 1.3.0.
  class ResourceLaunchRequest < LTI::Tokens::IdToken
    # Type name.
    TYPE = 'LtiResourceLinkRequest'.freeze

    # Claims in the resource link
    RESOURCE_LINK_ID = 'id'.freeze
    RESOURCE_LINK_DESCRIPTION = 'description'.freeze
    RESOURCE_LINK_TITLE = 'title'.freeze

    # Claims in the launch presentation
    LAUNCH_PRESENTATION_LOCALE = 'locale'.freeze

    # Claims in the platform properties
    PLATFORM_GUID = 'guid'.freeze
    PLATFORM_CONTACT_EMAIL = 'contact_email'.freeze
    PLATFORM_DESCRIPTION = 'description'.freeze
    PLATFORM_NAME = 'name'.freeze
    PLATFORM_URL = 'url'.freeze


    attr_reader :resource_link_id, :resource_link_description, :resource_link_title
    attr_reader :launch_presentation_locale
    attr_reader :platform_guid, :platform_contact_email, :platform_description, :platform_name, :platform_url

    def initialize(token_body)
      super(token_body)
      resource_link = token_body[LTI::Messages::Claims::RESOURCE_LINK] || {}
      @resource_link_id = resource_link[RESOURCE_LINK_ID]
      @resource_link_description = resource_link[RESOURCE_LINK_DESCRIPTION]
      @resource_link_title = resource_link[RESOURCE_LINK_TITLE]
      launch_presentation = token_body[LTI::Messages::Claims::LAUNCH_PRESENTATION] || {}
      @launch_presentation_locale = launch_presentation[LAUNCH_PRESENTATION_LOCALE]
      platform = token_body[LTI::Messages::Claims::PLATFORM] || {}
      @platform_guid = platform[PLATFORM_GUID]
      @platform_contact_email = platform[PLATFORM_CONTACT_EMAIL]
      @platform_description = platform[PLATFORM_DESCRIPTION]
      @platform_name = platform[PLATFORM_NAME]
      @platform_url = platform[PLATFORM_URL]
    end

    def as_json(options = nil)
      base = super(options)
      rl = {}
      rl[RESOURCE_LINK_ID] = resource_link_id if resource_link_id.present?
      rl[RESOURCE_LINK_DESCRIPTION] = resource_link_description if resource_link_description.present?
      rl[RESOURCE_LINK_TITLE] = resource_link_title
      base[LTI::Messages::Claims::RESOURCE_LINK] = rl
      lp = {}
      lp[LAUNCH_PRESENTATION_LOCALE] = launch_presentation_locale if launch_presentation_locale.present?
      base[LTI::Messages::Claims::LAUNCH_PRESENTATION] = lp if lp.present?
      platform = {}
      platform[PLATFORM_GUID] = platform_guid if platform_guid.present?
      platform[PLATFORM_CONTACT_EMAIL] = platform_contact_email if platform_contact_email.present?
      platform[PLATFORM_DESCRIPTION] = platform_description if platform_description.present?
      platform[PLATFORM_NAME] = platform_name if platform_name.present?
      platform[PLATFORM_URL] = platform_url if platform_url.present?
      base[LTI::Messages::Claims::PLATFORM] = platform if platform.present?
      base
    end
  end
end
