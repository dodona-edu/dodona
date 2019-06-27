class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Tenant ID's of known office365 organisations
  # who should use another sign in method
  UGENT_TID = 'd7811cde-ecef-496c-8f91-a1786241b99c'.freeze
  WAREGEM_TID = '9fdf506a-3be0-4f07-9e03-908ceeae50b4'.freeze
  TSM_TID = 'https://tsm.smartschool.be'.freeze
  CVO_TSM_TID = 'https://cvotsm.smartschool.be'.freeze
  BLACKLIST = [UGENT_TID, WAREGEM_TID, TSM_TID, CVO_TSM_TID].freeze

  def smartschool
    oauth_login
  end

  def office365
    oauth_login
  end

  def google_oauth2
    oauth_hash[:info][:institution] = oauth_hash.extra[:raw_info][:hd]
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

  def oauth_hash
    request.env['omniauth.auth']
  end

  def provider
    oauth_hash.provider
  end

  def institution_identifier
    oauth_hash.info.institution
  end

  def oauth_email
    oauth_hash.info.email
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
      if user.present?
        try_login!(user)
      else
        institution = create_institution
        user = User.from_institution(oauth_hash, institution)
        try_login!(user)
      end
    end
  end

  def create_institution
    institution = Institution.from_identifier(institution_identifier)
    if institution.blank?
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
  end

  def try_login!(user)
    raise 'User should not be nil here' if user.nil?
    if institution_matches?(user)
      user.update_from_oauth(oauth_hash, Institution.from_identifier(institution_identifier))
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
    end
  end

  def institution_created
    logger.info "Institution with identifier #{institution_identifier} created (#{provider}). " \
      "See below for more info about the request:\n" \
      "#{oauth_hash.pretty_inspect}"

    ApplicationMailer.with(authinfo: oauth_hash)
        .institution_created
        .deliver_later
  end

  def institution_creation_failed(errors)
    logger.info "Failed to created institution with identifier #{institution_identifier} (#{provider}). " \
      "See below for more info about the request:\n" \
      "#{oauth_hash.pretty_inspect}" \
      "#{errors}"

    ApplicationMailer.with(authinfo: oauth_hash, errors: errors)
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
