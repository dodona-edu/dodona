class Auth::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Tenant ID's of known Office365 organisations
  # who should use another sign in method
  # TODO refactor using redirect providers
  #      https://github.com/dodona-edu/dodona/issues/2067
  UGENT_TID = 'd7811cde-ecef-496c-8f91-a1786241b99c'.freeze
  WAREGEM_TID = '9fdf506a-3be0-4f07-9e03-908ceeae50b4'.freeze
  TSM_TID = 'https://tsm.smartschool.be'.freeze
  CVO_TSM_TID = 'https://cvotsm.smartschool.be'.freeze
  MAERLANT_TID = 'https://kabl-sgr25.smartschool.be'.freeze
  BLACKLIST = [UGENT_TID, WAREGEM_TID, TSM_TID, CVO_TSM_TID, MAERLANT_TID].freeze

  # Disable CSRF since the token information is lost.
  skip_before_action :verify_authenticity_token

  # ==> Failure route.

  def failure
    flash_failure request.params['error_message'] \
                                                  || request.params['error_description'] \
                                                  || I18n.t('devise.omniauth_callbacks.unknown_failure')
    redirect_to root_path
  end

  # ==> Provider callbacks.

  def google_oauth2
    auth_hash[:info][:institution] = auth_hash.extra[:raw_info][:hd]
    generic_oauth
  end

  def office365
    generic_oauth
  end

  def saml
    try_login!
  end

  def smartschool
    generic_oauth
  end

  private

  # ==> Authentication logic.

  def generic_oauth
    return provider_missing! if oauth_provider_id.blank?
    return provider_blacklisted! if BLACKLIST.include?(oauth_provider_id)

    # Find the provider for the current institution. If no provider exists yet,
    # a new one will be created.
    return redirect_with_flash!(I18n.t('auth.sign_in.errors.institution-creation')) if provider.blank?

    try_login!
  end

  def try_login!
    # Find the identity.
    identity = find_identity
    if identity.blank?
      # Create a new user and identity.
      user = User.new institution: provider&.institution
      identity = user.identities.build identifier: auth_uid, provider: provider
    end

    # Validation.
    raise 'Identity should not be nil here' if identity.nil?

    # Update the user information from the authentication response.
    user = identity.user
    user.update_from_provider(auth_hash, provider)
    return redirect_with_errors!(user) if user.errors.any?

    # User successfully updated, finish the authentication procedure.
    sign_in_and_redirect user, event: :authentication
  end

  # ==> Utilities.

  def find_identity
    # Attempt to find the identity by its identifier.
    identity = Identity.find_by(identifier: auth_uid, provider: provider)
    return identity if identity.present?

    # If the username is available and the provider is saml, regardless of
    # whether the identity exists, don't try to match the email address.
    return identity if auth_uid.present? && auth_provider_type == Provider::Saml.sym

    # No username was provided, try to find the user by the email address.
    user = User.from_email(auth_email)
    return nil if user.blank?

    # Find an identity for the user at the current provider.
    Identity.find_by(provider: provider, user: user)
  end

  def find_or_create_oauth_provider
    # Find an existing provider.
    provider_type = Provider.for_sym(auth_provider_type)
    provider = provider_type.find_by(identifier: oauth_provider_id)
    return provider if provider.present?

    # Provider was not found. Currently, a new institution will be created for
    # every new provider as well.
    institution = Institution.new name: Institution::NEW_INSTITUTION_NAME,
                                  short_name: Institution::NEW_INSTITUTION_NAME,
                                  logo: "#{auth_provider_type}.png"
    provider = institution.providers.build identifier: oauth_provider_id,
                                           type: provider_type.name

    if institution.save
      institution_created
      provider
    else
      institution_creation_failed institution.errors
      nil
    end
  end

  def flash_failure(reason)
    return unless is_navigational_format?

    set_flash_message :notice, :failure, kind: auth_provider_type || 'OAuth2', reason: reason
  end

  def redirect_with_errors!(resource)
    logger.info "User was unable to login because of reason: '#{resource.errors.full_messages.to_sentence}'. More info about the request below:\n" \
        "#{auth_hash.pretty_inspect}"

    ApplicationMailer.with(authinfo: auth_hash, errors: resource.errors.inspect)
                     .user_unable_to_log_in
                     .deliver_later

    redirect_with_flash! resource.errors.full_messages.to_sentence
  end

  def redirect_with_flash!(message)
    flash_failure message
    redirect_to root_path
  end

  # ==> Shorthands.

  def auth_hash
    request.env['omniauth.auth']
  end

  def auth_email
    auth_hash.info.email
  end

  def auth_provider_type
    auth_hash.provider
  end

  def auth_uid
    auth_hash.uid
  end

  def oauth_provider
    @oauth_provider ||= find_or_create_oauth_provider
  end

  def oauth_provider_id
    auth_hash.info.institution
  end

  def provider
    return auth_hash.extra.provider if auth_provider_type == Provider::Saml.sym

    oauth_provider
  end

  # ==> Event handlers.

  def institution_created
    logger.info "Institution with identifier #{oauth_provider_id} created (#{auth_provider_type}). " \
      "See below for more info about the request:\n" \
      "#{auth_hash.pretty_inspect}"

    ApplicationMailer.with(authinfo: auth_hash)
                     .institution_created
                     .deliver_later
  end

  def institution_create_failed(errors)
    logger.info "Failed to created institution with identifier #{oauth_provider_id} (#{auth_provider_type}). " \
      "See below for more info about the request:\n" \
      "#{auth_hash.pretty_inspect}" \
      "#{errors}"

    ApplicationMailer.with(authinfo: auth_hash, errors: errors.inspect)
                     .institution_creation_failed
                     .deliver_later
  end

  def provider_blacklisted!
    if oauth_provider_id == WAREGEM_TID
      # College Waregem uses two emails,
      # but we only allow <name>@sgpaulus.eu
      flash_failure I18n.t('auth.sign_in.blacklist.sgpaulus')
      redirect_to sign_in_path
    elsif oauth_provider_id == UGENT_TID
      # If an UGent-user logs in using Office365,
      # redirect to saml login
      redirect_to sign_in_path
    elsif oauth_provider_id == TSM_TID || oauth_provider_id == CVO_TSM_TID
      redirect_to omniauth_authorize_path(:users, Provider::Office365.sym)
    elsif oauth_provider_id == MAERLANT_TID
      redirect_to omniauth_authorize_path(:users, Provider::GSuite.sym)
    end
  end

  def provider_missing!
    set_flash_message \
      :notice,
      :failure,
      kind: auth_provider_type,
      reason: I18n.t('auth.sign_in.errors.missing-provider')
    redirect_to sign_in_path
  end
end
