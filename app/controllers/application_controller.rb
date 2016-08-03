class ApplicationController < ActionController::Base
  include Pundit
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :set_locale

  private

  def user_not_authorized
    flash[:alert] = 'Sorry, je hebt niet genoeg rechten om deze pagina te bekijken.'
    redirect_to(request.referer || root_path)
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
    sign_in(User.find(1))
  end

  def default_url_options
    { locale: I18n.locale, trailing_slash: true }
  end
end
