module LTI::Messages::Types
  # Defined in section 5 of IMS version 1.3.0.
  class ResourceLaunchRequest < IdToken
    # Type name.
    TYPE = 'LtiResourceLinkRequest'.freeze

    # Claims in the resource link
    RESOURCE_LINK_ID = 'id'.freeze
    RESOURCE_LINK_DESCRIPTION = 'description'.freeze
    RESOURCE_LINK_TITLE = 'title'.freeze

    # Claims in the launch presentation
    LAUNCH_PRESENTATION_LOCALE = 'locale'.freeze

    attr_reader :deployment_id
    attr_reader :resource_link_id
    attr_reader :resource_link_description
    attr_reader :resource_link_title
    attr_reader :launch_presentation_locale

    def initialize(token_body)
      super(token_body)
      @deployment_id = token_body[LTI::Messages::Claims::DEPLOYMENT_ID]
      resource_link = token_body[LTI::Messages::Claims::RESOURCE_LINK] || {}
      @resource_link_id = resource_link[RESOURCE_LINK_ID]
      @resource_link_description = resource_link[RESOURCE_LINK_DESCRIPTION]
      @resource_link_title = resource_link[RESOURCE_LINK_TITLE]
      launch_presentation = token_body[LTI::Messages::Claims::LAUNCH_PRESENTATION] || {}
      @launch_presentation_locale = launch_presentation[LAUNCH_PRESENTATION_LOCALE]
    end

    def as_json(options=nil)
      base = super(options)
      base[LTI::Messages::Claims::DEPLOYMENT_ID] = @deployment_id
      rl = {}
      rl[RESOURCE_LINK_ID] = @resource_link_id unless @resource_link_id
      rl[RESOURCE_LINK_DESCRIPTION] = @resource_link_description unless @resource_link_description.nil?
      rl[RESOURCE_LINK_TITLE] = @resource_link_title
      base[LTI::Messages::Claims::RESOURCE_LINK] = rl
      lp = {}
      lp[LAUNCH_PRESENTATION_LOCALE] = @launch_presentation_locale unless @launch_presentation_locale.nil?
      base[LTI::Messages::Claims::LAUNCH_PRESENTATION] = lp unless lp.empty?
      base
    end
  end
end
