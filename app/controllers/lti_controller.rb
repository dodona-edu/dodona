require_relative '../../lib/LTI/jwk.rb'
require_relative '../../lib/LTI/messages.rb'

class LtiController < ApplicationController
  include LTI::JWK
  include LTI::Messages

  before_action :set_lti_message, only: %i[content_selection]
  before_action :set_lti_provider, only: %i[content_selection]

  layout 'embedded'

  def content_selection
    # TODO: For testing purposes, the course, series and activity are chosen at
    #       random. This should be replaced by a form that allows the user to
    #       select something themself.
    @series = Series.first
    @course = @series.course
    @activity = @series.activities.first
  end

  def content_selection_payload
    # Parse the JWT token we have decoded in the first step.
    @lti_message = LTI::Messages::Types::DeepLinkingRequest.new(params[:lti][:decoded_token])

    # Parse the chosen activity.
    activity = Activity.find(params[:lti][:activity])
    url = course_series_activity_url(params[:lti][:course], params[:lti][:series], activity.id)

    # Build a new response message.
    response = LTI::Messages::Types::DeepLinkingResponse.new(@lti_message)
    response.items << LTI::Messages::Types::DeepLinkingResponse::LtiResourceLink.new(activity.name, url)

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
