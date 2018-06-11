class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def oauth
    user_login
  end

  def office365
    user_login
  end


  def failure
    reason = request.params['error_message'] \
              || request.params['error_description'] \
              || t('devise.omniauth_callbacks.unknown_failure')
    if is_navigational_format?
      set_flash_message :notice,
                        :failure,
                        kind: 'OAuth2',
                        reason: reason
    end
    redirect_to root_path
  end

  private

  def user_login
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user&.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: 'OAuth2') if is_navigational_format?
    else
      if is_navigational_format?
        set_flash_message :notice,
                          :failure,
                          kind: 'OAuth2',
                          reason: t('devise.omniauth_callbacks.user_not_created')
      end
      redirect_to root_path
    end
  end
end
