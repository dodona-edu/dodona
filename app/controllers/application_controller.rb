class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include SetCurrentRequestDetails
  include ApplicationHelper

  MAX_STORED_URL_LENGTH = 1024

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :bad_request
  rescue_from ActionController::ParameterMissing, with: :bad_request

  protect_from_forgery with: :null_session

  before_action :store_current_location,
                except: %i[media sign_in institution_not_supported privacy_prompt accept_privacy_policy],
                unless: -> { devise_controller? || remote_request? }

  before_action :skip_session,
                if: :sandbox?

  before_action :redirect_to_default_host,
                if: :sandbox?

  before_action :set_locale

  before_action :look_for_token, unless: :current_user

  around_action :user_time_zone, if: :current_user

  after_action :set_user_seen_at, if: -> { current_user && !js_request? }

  before_action :set_time_zone_offset

  before_action :set_notifications, if: :user_signed_in?
  before_action :set_unread_announcement, unless: :remote_request?

  impersonates :user

  # A more lax CSP for pages in the sandbox
  content_security_policy if: :sandbox? do |policy|
    policy.directives.clear
    sources = %i[self unsafe_inline https]
    sources << :http if Rails.env.development?
    policy.default_src(*sources)
    policy.script_src(*sources)
  end

  content_security_policy do |policy|
    policy.frame_ancestors '*'
  end

  def after_sign_in_path_for(_resource)
    stored_location_for(:user) || root_path
  end

  def after_sign_out_path_for(_resource)
    stored_location_for(:user) || root_path
  end

  Warden::Manager.after_authentication do |user, _auth, _opts|
    if user.email.blank? && !user.institution&.uses_lti? && !user.institution&.uses_oidc? && !user.institution&.uses_smartschool?
      raise "User with id #{user.id} should not have a blank email " \
            'if the provider is not LTI, OIDC or Smartschool'
    end
    user.touch(:sign_in_at)
  end

  Warden::Manager.after_set_user do |user, _auth, _opts|
    Rack::MiniProfiler.authorize_request if user.zeus?
  end

  protected

  def remote_request?
    request.format.js? || request.format.json?
  end

  def js_request?
    request.format.js?
  end

  def parse_pagination_param(page)
    # This doesn't work for negative numbers, but we don't need to handle negative numbers here anyway
    page.to_s.match(/^\d+$/) ? [page.to_i, 1].max : nil
  end

  def skip_session
    request.session_options[:skip] = true
  end

  def sandbox?
    request.host == Rails.configuration.sandbox_host && \
      request.host != Rails.configuration.default_host
  end

  private

  def redirect_to_default_host
    redirect_to({ host: Rails.configuration.default_host, params: request.query_parameters }, { allow_other_host: true })
  end

  def user_not_authorized
    if remote_request? || sandbox?
      if current_user.nil?
        # rubocop:disable Rails/RenderInline
        render status: :unauthorized,
               inline: 'You are not authorized to view this page.'
        # rubocop:enable Rails/RenderInline
      else
        head :forbidden
      end
    elsif current_user.nil?
      redirect_to sign_in_path
    else
      flash[:alert] = I18n.t('errors.no_rights')
      if request.referer.present? && URI.parse(request.referer).host == request.host
        redirect_to(request.referer)
      else
        redirect_to(root_path)
      end
    end
  end

  def bad_request
    # rubocop:disable Rails/RenderInline
    render status: :bad_request, inline: 'Bad request'
    # rubocop:enable Rails/RenderInline
  end

  def set_locale
    helpers.locale = params[:locale] || current_user&.lang || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale, trailing_slash: true, host: Rails.configuration.default_host }
  end

  def ensure_trailing_slash
    redirect_to url_for(trailing_slash: true), status: :permanent_redirect unless trailing_slash? || request.format == :json || request.format == :js
  end

  def trailing_slash?
    request.env['REQUEST_URI'].match(/[^?]+/).to_s.last == '/'
  end

  def store_current_location
    url = if request.url.length > MAX_STORED_URL_LENGTH
            request.base_url + request.path
          else
            request.url
          end
    store_location_for :user, url
  end

  def look_for_token
    token = request.headers['Authorization']&.strip
    return if token.blank?

    # Sessions are not needed for the JSON API
    skip_session

    token.gsub!(/Token token="(.*)"/, '\1')
    # only allow urlsafe base64 characters to pass
    token.gsub!(/[^A-Za-z0-9_\-]/, '')

    # Do not search for empty strings
    api_token = ApiToken.find_token(token) if token.present?

    if api_token
      sign_in api_token.user
    else
      head :unauthorized
    end
  end

  def user_time_zone(&)
    Time.use_zone(current_user.time_zone, &)
  end

  def set_time_zone_offset
    @time_zone_offset = Time.zone.now.utc_offset / -60
  end

  def set_notifications
    @last_notifications = current_user.notifications.limit(5).to_a
    @unread_notifications = @last_notifications.any? ? current_user.notifications.where(read: false).to_a : []
    @unread_notifications.delete_if do |n|
      if helpers.current_page?(helpers.base_notifiable_url_params(n))
        n.update(read: true)
        true
      end
    end
    # This variable counts for which services the dot in the favicon should be shown.
    # On most pages this will be empty or contain :notifications
    @dot_icon = @unread_notifications.any? ? %i[notifications] : []
  end

  def set_unread_announcement
    @unread_announcement = AnnouncementPolicy::Scope.new(current_user, Announcement.all).resolve.unread_by(current_user).first
  end

  def set_user_seen_at
    current_user.touch(:seen_at)
  end
end
