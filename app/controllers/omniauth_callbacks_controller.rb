class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Tenant ID's of known office365 organisations
  # who should use another sign in method
  UGENT_TID = 'd7811cde-ecef-496c-8f91-a1786241b99c'.freeze
  WAREGEM_TID = '9fdf506a-3be0-4f07-9e03-908ceeae50b4'.freeze
  TSM_TID = 'https://tsm.smartschool.be'.freeze
  CVO_TSM_TID = 'https://cvotsm.smartschool.be'.freeze
  MAERLANT_TID = 'https://kabl-sgr25.smartschool.be'.freeze
  BLACKLIST = [UGENT_TID, WAREGEM_TID, TSM_TID, CVO_TSM_TID, MAERLANT_TID].freeze

  # Disable CSRF since the token information is lost.
  skip_before_action :verify_authenticity_token

  # Provider callbacks.

  def google_oauth2
    auth_hash[:info][:institution] = auth_hash.extra[:raw_info][:hd]
    oauth_login
  end

  def office365
    oauth_login
  end

  def saml
    # Find the user.
    user = saml_find_user
    if user.blank?
      # User was still not found, create a new one.
      institution = auth_hash.extra.institution
      user = User.from_institution(auth_hash, institution)
    end
    try_login!(user)
  end

  def smartschool
    oauth_login
  end

  # Error handler.

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

  def saml_find_user
    # Attempt to find the user by its username.
    user = User.find_by(username: auth_hash.uid)
    return user if user.present?

    # Attempt to find the user by its email address.
    user = User.from_email(oauth_email)

    # Return the user if the username was not set.
    user&.username.blank? ? user : nil
  end

  def auth_hash
    request.env['omniauth.auth']
  end

  def provider
    auth_hash.provider
  end

  def institution_identifier
    auth_hash.info.institution
  end

  def oauth_email
    auth_hash.info.email
  end

  def institution_matches?(user)
    return true if user.institution.nil?

    if user.institution&.identifier != institution_identifier \
              || user.institution&.provider != provider
      user.errors.add(:institution, 'mismatch')
      false
    else
      true
    end
  end

  def oauth_login
    # Blacklist: institutions who should use another
    # login method
    if institution_identifier.blank?
      no_institution_found!
    elsif BLACKLIST.include?(institution_identifier)
      handle_blacklisted_institutions!
    else
      user = User.from_email(oauth_email)
      if user.blank?
        institution = create_institution
        user = User.from_institution(auth_hash, institution)
      end
      try_login!(user)
    end
  end

  def create_institution
    institution = Institution.from_identifier(institution_identifier)
    return institution if institution.present?

    institution = Institution.new(name: Institution::NEW_INSTITUTION_NAME,
                                  short_name: Institution::NEW_INSTITUTION_NAME,
                                  logo: "#{provider}.png",
                                  provider: provider,
                                  identifier: institution_identifier)
    if institution.save
      institution_created
      institution
    else
      institution_creation_failed institution.errors
      nil
    end
  end

  def try_login!(user)
    raise 'User should not be nil here' if user.nil?

    if institution_matches?(user)
      user.update_from_oauth(auth_hash, Institution.from_identifier(institution_identifier))
      if user.errors.none?
        sign_in_and_redirect user, event: :authentication
        if is_navigational_format?
          set_flash_message \
            :notice,
            :success,
            kind: provider
        end
      else
        redirect_with_errors!(user)
      end
    else
      redirect_with_errors!(user)
    end
  end

  def redirect_with_errors!(user)
    logger.info "User was unable to login because of reason: '#{user.errors.full_messages.to_sentence}'. More info about the request below:\n" \
      "#{auth_hash.pretty_inspect}"

    ApplicationMailer.with(authinfo: auth_hash, errors: user.errors.inspect)
                     .user_unable_to_log_in
                     .deliver_later

    if is_navigational_format?
      set_flash_message \
        :notice,
        :failure,
        kind: provider,
        reason: user.errors.full_messages.to_sentence
    end
    redirect_to root_path
  end

  def handle_blacklisted_institutions!
    if institution_identifier == WAREGEM_TID
      # College Waregem uses two emails,
      # but we only allow <name>@sgpaulus.eu
      set_flash_message \
        :notice,
        :failure,
        kind: provider,
        reason: 'gebruik je sgpaulus-account ' \
                '(voornaam.naam@sgpaulus.eu) ' \
                'om in te loggen op Dodona'
      redirect_to sign_in_path

    elsif institution_identifier == UGENT_TID
      # If an UGent-user logs in using office365,
      # redirect to saml login
      redirect_to sign_in_path(idp: 'UGent')
    elsif institution_identifier == TSM_TID || institution_identifier == CVO_TSM_TID
      redirect_to user_office365_omniauth_authorize_path
    elsif institution_identifier == MAERLANT_TID
      redirect_to user_google_oauth2_omniauth_authorize_path
    end
  end

  def institution_created
    logger.info "Institution with identifier #{institution_identifier} created (#{provider}). " \
      "See below for more info about the request:\n" \
      "#{auth_hash.pretty_inspect}"

    ApplicationMailer.with(authinfo: auth_hash)
                     .institution_created
                     .deliver_later
  end

  def institution_creation_failed(errors)
    logger.info "Failed to created institution with identifier #{institution_identifier} (#{provider}). " \
      "See below for more info about the request:\n" \
      "#{auth_hash.pretty_inspect}" \
      "#{errors}"

    ApplicationMailer.with(authinfo: auth_hash, errors: errors.inspect)
                     .institution_creation_failed
                     .deliver_later
  end

  def no_institution_found!
    set_flash_message \
      :notice,
      :failure,
      kind: provider,
      reason: I18n.t('pages.sign_in_page.has_to_have_institution')
    redirect_to sign_in_path
  end
end
