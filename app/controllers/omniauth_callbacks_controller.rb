class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def zeuswpi
    @user = User.from_omniauth(request.env['omniauth.auth'])

    sign_in_and_redirect @user, event: :authentication
    set_flash_message(:notice, :success, kind: 'Zeus WPI') if is_navigational_format?
  end

  def failure
    redirect_to root_path
  end
end
