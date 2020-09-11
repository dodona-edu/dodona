require_relative '../../lib/LTI/jwk.rb'
require_relative '../../lib/LTI/messages.rb'

class LtiController < ApplicationController
  include LTI::JWK
  include LTI::Messages

  before_action :set_lti_message, only: %i[content_selection]
  before_action :set_lti_provider, only: %i[content_selection]

  layout 'embedded'

  def redirect
    @path = lti_do_redirect_path(sym: params[:sym], provider: params[:provider])
    @browser_path = lti_do_redirect_path(sym: params[:sym], provider: params[:provider], browser: true)
    session[:manual_redirect] = true
  end

  def do_redirect
    if session[:manual_redirect].present?
      # This is the first we hit this path, so redirect to the provider.
      if params[:browser].blank?
        # If we were called in an iframe, don't redirect at the end of the process.
        session.delete(:original_redirect)
        session[:hide_flash] = true
      end
      session.delete(:manual_redirect)
      redirect_to omniauth_authorize_path(:user, params[:sym], provider: params[:provider])
    elsif session[:original_redirect].present?
      # This is the second time we hit this path: we were redirected from the main provider.
      # There is an original target, so we are not in an iframe. Redirect to the original target.
      original = session[:original_redirect]
      session.delete(:original_redirect)
      redirect_to original
    else
      # This is the second time we hit this path: we were redirected from the main provider.
      # We are in an iframe, so tell the user that they should close the page.
      render 'redirected'
    end
  end

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
