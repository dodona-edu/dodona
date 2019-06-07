class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Tenant ID's of known office365 organisations
  # who should use another sign in method
  UGENT_TID = 'd7811cde-ecef-496c-8f91-a1786241b99c'.freeze
  WAREGEM_TID = '9fdf506a-3be0-4f07-9e03-908ceeae50b4'.freeze
  BLACKLIST = [UGENT_TID, WAREGEM_TID].freeze

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
    raise 'No institution found' if institution_identifier.blank?

    # Blacklist: institutions who should use another
    # login method
    if BLACKLIST.include?(institution_identifier)
      handle_blacklisted_institutions!
    else
      user = User.from_email(oauth_email)
      if user.present?
        try_login!(user)
      else
        institution = Institution.from_identifier(institution_identifier)
        if institution.blank?
          institution = Institution.create(name: Institution::NEW_INSTITUTION_NAME,
                                           short_name: Institution::NEW_INSTITUTION_NAME,
                                           logo: "#{provider}.png",
                                           provider: provider,
                                           identifier: institution_identifier)
          institution_created
        end
        user = User.from_institution(oauth_hash, institution)
        try_login!(user)
      end
    end
  end

  def try_login!(user)
    raise 'User should not be nil here' if user.nil?
    if institution_matches?(user)
      user.update_from_oauth(oauth_hash)
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
end
