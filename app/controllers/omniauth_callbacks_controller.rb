class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def smartschool
    oauth_login
  end

  def office365
    oauth_login
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

  def provider
    request.env['omniauth.auth']&.provider
  end

  def institution_identifier
    request.env['omniauth.auth']&.info&.institution
  end

  def oauth_login
    raise ActiveRecord::RecordNotFound if institution_identifier.blank?

    institution = Institution.from_identifier(institution_identifier)

    if institution.present? && institution.provider.to_s == provider

      user = User.from_omniauth(request.env['omniauth.auth'], institution)
      if user&.persisted?
        sign_in_and_redirect user, event: :authentication
        set_flash_message(:notice, :success, kind: provider) if is_navigational_format?
      else
        if is_navigational_format?
          set_flash_message :notice,
                            :failure,
                            kind: provider,
                            reason: user.errors.full_messages.to_sentence
        end
        redirect_to root_path
      end
    else
      reject_institution!
    end
  end

  # Tenant ID's of known office365 organisations who should use another sign in method
  UGENT_TID = 'd7811cde-ecef-496c-8f91-a1786241b99c'.freeze
  WAREGEM_TID = '9fdf506a-3be0-4f07-9e03-908ceeae50b4'.freeze

  def reject_institution!
    if institution_identifier == WAREGEM_TID
      # College Waregem uses two emails, but we only allow <name>@sgpaulus.eu
      set_flash_message :notice,
                        :failure,
                        kind: provider,
                        reason: 'gebruik je sgpaulus-account (voornaam.naam@sgpaulus.eu) om in te loggen op Dodona'
      redirect_to sign_in_path
    elsif institution_identifier == UGENT_TID
      # If an UGent-user logs in using office365, redirect to saml login
      redirect_to sign_in_path(idp: 'UGent')
    else
      logger.info "OAuth login using #{provider} with identifier #{institution_identifier} rejected (not whitelisted). See below for more info about the request:\n#{request.env['omniauth.auth'].pretty_inspect}"

      ApplicationMailer.with(authinfo: request.env['omniauth.auth']).login_rejected.deliver_later

      session[:provider] = provider
      redirect_to institution_not_supported_path
    end
  end
end
