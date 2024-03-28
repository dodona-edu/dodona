class LtiController < ApplicationController
  include SetLtiMessage

  before_action :set_lti_message, only: %i[content_selection]
  before_action :set_lti_provider, only: %i[content_selection]

  layout 'lti'

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
    return head :unauthorized unless current_user&.a_course_admin?

    @supported = @lti_message.accept_types.include?(LTI::Messages::Types::DeepLinkingResponse::LtiResourceLink::TYPE)
    @grouped_courses = current_user.administrating_courses.group_by(&:year)
    @multiple = @lti_message.accept_multiple
  end

  def series_and_activities
    # Eager load the activities
    @course = Course.includes(series: [:activities]).find_by(id: params[:id])

    return head :unauthorized unless current_user&.admin_of?(@course)

    @series = policy_scope(@course.series)
    @multiple = ActiveModel::Type::Boolean.new.cast(params[:multiple])
  end

  def content_selection_payload
    # Parse the JWT token we have decoded in the first step.
    @lti_message = LTI::Messages::Types::DeepLinkingRequest.new(params[:lti][:decoded_token])

    # Build a new response message.
    response = LTI::Messages::Types::DeepLinkingResponse.new(@lti_message)
    response.items += helpers.lti_resource_links_from(params)

    render json: { payload: encode_and_sign(response) }
  end

  def jwks
    render json: { keys: keyset }
  end
end
