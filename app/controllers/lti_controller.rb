require_relative '../../lib/LTI/jwk.rb'
require_relative '../../lib/LTI/messages.rb'

class LtiController < ApplicationController
  include LtiHelper
  include LTI::JWK
  include LTI::Messages

  before_action :set_lti_message, only: %i[content_selection]
  before_action :set_lti_provider, only: %i[content_selection]

  layout 'embedded'

  def content_selection
    @supported = @lti_message.accept_types.include?(LTI::Messages::Types::DeepLinkingResponse::LtiResourceLink::TYPE)
    @grouped_courses = policy_scope(Course.all).group_by(&:year)
    @multiple = @lti_message.accept_multiple
  end

  def series_and_activities
    # Eager load the activities
    @course = Course.includes(series: [:activities]).find_by(id: params[:id])
    @series = policy_scope(@course.series)
    @multiple = ActiveModel::Type::Boolean.new.cast(params[:multiple])
  end

  def content_selection_payload
    # Parse the JWT token we have decoded in the first step.
    @lti_message = LTI::Messages::Types::DeepLinkingRequest.new(params[:lti][:decoded_token])

    # Build a new response message.
    response = LTI::Messages::Types::DeepLinkingResponse.new(@lti_message)
    response.items += lti_resource_links_from(params)

    render json: { payload: encode_and_sign(response) }
  end

  def jwks
    render json: { keys: keyset }
  end

  private

  def set_lti_message
    @lti_message = parse_message(params[:id_token], params[:provider_id])
  end

  def set_lti_provider
    @provider = Provider::Lti.find(params[:provider_id])
  end
end
