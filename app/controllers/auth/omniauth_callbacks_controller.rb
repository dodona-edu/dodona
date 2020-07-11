class Auth::OmniauthCallbacksController < Devise::OmniauthCallbacksController
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

  def lti
    try_login!
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

    # Find the provider for the current institution. If no provider exists yet,
    # a new one will be created.
    return redirect_with_flash!(I18n.t('auth.sign_in.errors.institution-creation')) if provider.blank?

    try_login!
  end

  def try_login!
    # Ensure the preferred provider is used.
    # TODO add link providers.
    # return redirect_to_preferred_provider! unless provider.prefer?

    # Find the identity.
    identity, user = find_identity_and_user
    if identity.blank?
      # Create a new user and identity.
      user = User.new institution: provider&.institution if user.blank?
      identity = user.identities.build identifier: auth_uid, provider: provider
    end

    # Validation.
    raise 'Identity should not be nil here' if identity.nil?

    # Update the user information from the authentication response.
    user.update_from_provider(auth_hash, provider)
    return redirect_with_errors!(user) if user.errors.any?

    # User successfully updated, finish the authentication procedure.
    sign_in_and_redirect user, event: :authentication
  end

  # ==> Utilities.

  def find_identity_and_user
    # Attempt to find the identity by its identifier.
    identity = Identity.find_by(identifier: auth_uid, provider: provider)
    return [identity, identity.user] if identity.present? && auth_uid.present?

    # No username was provided, try to find the user using the email address.
    user = User.from_email(auth_email)
    return [nil, nil] if user.blank?

    # Find an identity for the user at the current provider.
    [Identity.find_by(provider: provider, user: user), user]
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

  def redirect_to_preferred_provider!
    # Find the preferred provider for the current institution.
    preferred_provider = provider.institution.preferred_provider

    # Redirect to the provider.
    redirect_to omniauth_authorize_path(:user, preferred_provider.class.sym, provider: preferred_provider)
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
    return nil if auth_hash.blank?

    auth_hash.provider.to_sym
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

  def provider_missing!
    flash_failure I18n.t('auth.sign_in.errors.missing-provider')
    redirect_to sign_in_path
  end
end
