require_relative '../../lib/LTI/jwk.rb'
require_relative '../../lib/LTI/messages.rb'

class LtiController < ApplicationController
  include LTI::JWK
  include LTI::Messages

  before_action :set_lti_message, only: %i[content_selection]
  before_action :set_lti_provider, only: %i[content_selection]

  layout 'embedded'

  def content_selection
    @supported = @lti_message.accept_types.include?(LTI::Messages::Types::DeepLinkingResponse::LtiResourceLink::TYPE)
    courses = policy_scope(Course.all)
    @grouped_courses = courses.group_by(&:year)
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
    response.items += create_items_from_params(params)

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

  def create_items_from_params(params)
    # Get the arguments
    activity_ids = params[:lti][:activities] || []
    series_id = params[:lti][:series]
    course_id = params[:lti][:course]

    if activity_ids.present?
      # We can have multiple ids.
      activities = Activity.find(activity_ids)
      activities.map do |activity|
        url = course_series_activity_url(course_id, series_id, activity.id)
        LTI::Messages::Types::DeepLinkingResponse::LtiResourceLink.new(activity.name, url)
      end
    elsif series_id.present?
      series = Series.find(series_id)
      url = get_series_url(course_id, series)
      [LTI::Messages::Types::DeepLinkingResponse::LtiResourceLink.new(series.name, url)]
    else
      course = Course.find(course_id)
      url = get_course_url(course)
      [LTI::Messages::Types::DeepLinkingResponse::LtiResourceLink.new(course.name, url)]
    end
  end

  def get_series_url(course_id, series)
    if series.hidden?
      series_url(series, token: series.access_token)
    else
      course_url(course_id, anchor: series.anchor)
    end
  end

  def get_course_url(course)
    if course.secret_required?
      course_url(course, secret: course.secret)
    else
      course_url(course)
    end
  end
end
