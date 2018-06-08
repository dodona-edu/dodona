class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def oauth
    byebug
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

  def failure
    reason = if request.params.key?('error_message')
               request.params['error_message']
             else
               t('devise.omniauth_callbacks.unknown_failure')
             end
    if is_navigational_format?
      set_flash_message :notice,
                        :failure,
                        kind: 'OAuth2',
                        reason: reason
    end
    redirect_to root_path
  end
end
