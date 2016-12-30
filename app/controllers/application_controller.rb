class ApplicationController < ActionController::Base
  include Pundit
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :store_current_location, unless: :devise_controller?, except: [:media]

  before_action :set_locale

  around_action :user_time_zone, if: :current_user

  skip_before_action :verify_authenticity_token, if: :js_request?

  impersonates :user

  def after_sign_in_path_for(_resource)
    stored_location_for(:user) || root_path
  end

  def after_sign_out_path_for(_resource)
    stored_location_for(:user) || root_path
  end

  protected

  def js_request?
    request.format.js?
  end

  private

  def user_not_authorized
    if current_user.nil?
      redirect_to new_user_session_path
    else
      flash[:alert] = I18n.t('errors.no_rights')
      redirect_to(request.referer || root_path)
    end
  end

  def set_locale
    I18n.locale = params[:locale] || (current_user&.lang) || I18n.default_locale
    current_user&.update(lang: I18n.locale.to_s)
  end

  def default_url_options
    { locale: I18n.locale, trailing_slash: true }
  end

  def ensure_trailing_slash
    redirect_to url_for(trailing_slash: true), status: 301 unless trailing_slash?
  end

  def trailing_slash?
    request.env['REQUEST_URI'].match(/[^\?]+/).to_s.last == '/'
  end

  def store_current_location
    store_location_for(:user, request.url)
  end

  def user_time_zone(&block)
    Time.use_zone(current_user.time_zone, &block)
  end
end
