class ApplicationController < ActionController::Base
  include Pundit
  include SetCurrentRequestDetails

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :store_current_location,
                except: %i[media sign_in_page institution_not_supported],
                unless: -> { devise_controller? || remote_request? }

  before_action :set_locale

  before_action :look_for_token, unless: :current_user

  around_action :user_time_zone, if: :current_user

  before_action :set_time_zone_offset

  impersonates :user

  def after_sign_in_path_for(_resource)
    stored_location_for(:user) || root_path
  end

  def after_sign_out_path_for(_resource)
    stored_location_for(:user) || root_path
  end

  Warden::Manager.after_authentication do |user, auth, _opts|
    if user.institution.nil?
      idp = Institution.find_by(short_name: auth.env['rack.session'][:current_idp])
      user.update(institution: idp)
    end
    if user.email.blank? && !user.institution&.smartschool?
      raise "User with id #{user.id} should not have a blank email " \
            'if the provider is not smartschool'
    end
  end

  protected

  def remote_request?
    request.format.js? || request.format.json?
  end

  def parse_pagination_param(page)
    # This doesn't work for negative numbers, but we don't need to handle negative numbers here anyway
    page.to_s.match(/^\d+$/) ? [page.to_i, 1].max : nil
  end

  private

  def user_not_authorized
    if remote_request?
      if current_user.nil?
        head :unauthorized
      else
        head :forbidden
      end
    else
      if current_user.nil?
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
  end

  def set_locale
    begin
      I18n.locale = params[:locale] || (current_user&.lang) || I18n.default_locale
    rescue I18n::InvalidLocale
      I18n.locale = I18n.default_locale
    end
    current_user&.update(lang: I18n.locale.to_s)
  end

  def default_url_options
    { locale: I18n.locale, trailing_slash: true }
  end

  def ensure_trailing_slash
    redirect_to url_for(trailing_slash: true), status: :permanent_redirect unless trailing_slash? || request.format == :json || request.format == :js
  end

  def trailing_slash?
    request.env['REQUEST_URI'].match(/[^\?]+/).to_s.last == '/'
  end

  def store_current_location
    store_location_for(:user, request.url)
  end

  def look_for_token
    token = request.headers['Authorization']&.strip
    return if token.blank?

    # Sessions are not needed for the JSON API
    request.session_options[:skip] = true

    token.gsub!(/Token token=\"(.*)\"/, '\1')
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

  def user_time_zone(&block)
    Time.use_zone(current_user.time_zone, &block)
  end

  def set_time_zone_offset
    @time_zone_offset = Time.zone.now.utc_offset / -60
  end
end
