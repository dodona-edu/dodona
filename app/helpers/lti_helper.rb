require_relative '../../lib/LTI/messages'

module LtiHelper
  def lti_resource_links_from(params)
    activity_ids = params[:lti][:activities]&.reject(&:blank?) || []
    series_id = params[:lti][:series]
    course_id = params[:lti][:course]

    if activity_ids.present?
      # We can have multiple ids.
      activities = Activity.find(activity_ids)
      activities.map do |activity|
        url = lti_activity_url(course_id, series_id, activity)
        LTI::Messages::Types::DeepLinkingResponse::LtiResourceLink.new(activity.name, url)
      end
    elsif series_id.present?
      series = Series.find(series_id)
      url = lti_series_url(series)
      [LTI::Messages::Types::DeepLinkingResponse::LtiResourceLink.new(series.name, url)]
    else
      course = Course.find(course_id)
      url = lti_course_url(course)
      [LTI::Messages::Types::DeepLinkingResponse::LtiResourceLink.new(course.name, url)]
    end
  end

  def lti_activity_url(course_id, series_id, activity)
    course_series_activity_url(course_id, series_id, activity.id)
  end

  def lti_course_url(course)
    if course.secret_required?
      course_url(course, secret: course.secret)
    else
      course_url(course)
    end
  end

  def lti_series_url(series)
    if series.hidden?
      series_url(series, token: series.access_token)
    else
      series_url(series)
    end
  end
end
