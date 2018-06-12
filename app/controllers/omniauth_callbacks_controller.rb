class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def smartschool
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

  WHITELIST = {
    'https://slow.smartschool.be'          => { provider: :smartschool,     name: 'SLO Wetenschappen' },
    'https://college-ieper.smartschool.be' => { provider: :smartschool,     name: 'College Ieper'     },
    'd7811cde-ecef-496c-8f91-a1786241b99c' => { provider: :office365,       name: 'UGent Office365'   },
    '9fdf506a-3be0-4f07-9e03-908ceeae50b4' => { provider: :office365,       name: 'College Waregem'   }
  }.freeze

  def provider
    request.env['omniauth.auth']&.provider
  end

  def institution
    request.env['omniauth.auth']&.info&.institution
  end

  def whitelisted?
    if WHITELIST.key?(institution) && WHITELIST[institution][:provider] == provider.to_sym
      return true
    end
    byebug

    if is_navigational_format?
      set_flash_message :notice,
                        :failure,
                        kind: provider,
                        reason: t('devise.omniauth_callbacks.not_whitelisted')
    end
    redirect_to root_path
    false
  end

  def user_login
    return unless whitelisted?
    institution_name = WHITELIST[institution][:name]

    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user&.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: provider) if is_navigational_format?
    else
      if is_navigational_format?
        set_flash_message :notice,
                          :failure,
                          kind: provider,
                          reason: t('devise.omniauth_callbacks.user_not_created')
      end
      redirect_to root_path
    end
  end
end
