class ApplicationController < ActionController::Base
  include Pundit
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :store_current_location, unless: :devise_controller?

  before_action :set_locale

  impersonates :user

  def after_sign_in_path_for(_resource)
    stored_location_for(:user) || root_path
  end

  def after_sign_out_path_for(_resource)
    stored_location_for(:user) || root_path
  end

  private

  def user_not_authorized
    flash[:alert] = I18n.t('errors.no_rights')
    redirect_to(request.referer || root_path)
  end

  def set_locale
    I18n.locale = params[:locale] || (current_user && current_user.lang) || I18n.default_locale
    current_user.update(lang: I18n.locale.to_s) if current_user
  end

  def default_url_options
    { locale: I18n.locale, trailing_slash: true }
  end

  def store_current_location
    store_location_for(:user, request.url)
  end
end
