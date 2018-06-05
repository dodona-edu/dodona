class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def zeuswpi
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user&.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: 'Zeus WPI') if is_navigational_format?
    else
      logger.debug "Unable to log in user with omniauth: #{requst.env['omniauth.auth']}"
      set_flash_message(:notice, :failure, kind: 'Zeus WPI') if is_navigational_format?
      redirect_to root_path
    end
  end

  def failure
    redirect_to root_path
  end
end
