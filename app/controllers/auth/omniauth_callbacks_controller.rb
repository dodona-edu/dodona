class Auth::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Disable CSRF since the token information is lost.
  skip_before_action :verify_authenticity_token

  # ==> Failure route.

  def failure
    # Find the error message and log it for analysis.
    error_message = failure_message ||
                    request.params['error_description'] ||
                    I18n.t('devise.omniauth_callbacks.unknown_failure')
    logger.error error_message

    # Show a flash message and redirect.
    flash_failure error_message
    redirect_to root_path, status: :bad_request
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
    # Ensure that an appropriate provider is used.
    return redirect_to_preferred_provider! if provider.redirect?

    # Find the identity.
    identity, user = find_identity_and_user

    if identity.blank?
      # If no identity was found and the provider is a link provider, prompt the
      # user to sign in with a preferred provider.
      return redirect_to_preferred_provider! if provider.link?

      # Create a new user and identity.
      user = User.new institution: provider&.institution if user.blank?
      identity = user.identities.build identifier: auth_uid, provider: provider
    end

    # Validation.
    raise 'Identity should not be nil here' if identity.nil?

    # Update the user information from the authentication response.
    user.update_from_provider(auth_hash, provider)
    return redirect_with_errors!(user) if user.errors.any?

    # Link the stored identifier to the signed in user.
    create_linked_identity!(user)

    # User successfully updated, finish the authentication procedure. Force is
    # required to overwrite the current existing user.
    sign_in user, event: :authentication, force: true

    # Redirect the user to their destination.
    redirect_to_target!(user)
  end

  # ==> Utilities.

  def create_linked_identity!(user)
    # Find the link provider and uid in the session.
    link_provider_id = session.delete(:auth_link_provider_id)
    link_uid = session.delete(:auth_link_uid)
    return if link_provider_id.blank? || link_uid.blank?

    # Find the actual provider.
    link_provider = Provider.find(link_provider_id)
    return if link_provider.blank?

    # Create the identity for the current user.
    Identity.create(identifier: link_uid, provider: link_provider, user: user)

    unless session[:hide_flash]
      # Set a flash message.
      set_flash_message :notice, :linked
    end
    session.delete(:hide_flash)
  end

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

    # Get the provider type.
    provider_type = auth_provider_type || request.env['omniauth.error.strategy']&.name || 'OAuth2'
    set_flash_message :notice, :failure, kind: provider_type, reason: reason
  end

  def redirect_to_preferred_provider!
    # Store the uid and the id of the current provider in the session, to link
    # the identities after returning.
    session[:auth_link_provider_id] = provider.id if provider.link?
    session[:auth_link_uid] = auth_uid if provider.link?

    # Find the preferred provider for the current institution.
    preferred_provider = provider.institution.preferred_provider

    # If this is the first time a user is logging in with LTI, we do something special: LTI
    # related screens are often shown inside an iframe, which some providers don't support
    # (for example, UGent SAML doesn't).
    # We try our best to detect an iframe with the Sec-Fetch-Dest header, but at the time of
    # writing, Firefox and Safari don't support it.
    if provider.type == 'Provider::Lti' && request.headers['Sec-Fetch-Dest'] != 'document'
      # The header is nil, in which case we don't know if it is an iframe or not, or the header is
      # "iframe", in which case we do know it is an iframe.
      # Anyway, we save the original target, and redirect to a web page.
      # Don't save the complete URL, since they contain potentially big params.
      session[:original_redirect] = URI.parse(target_path(:user)).path
      redirect_to users_lti_redirect_path(sym: preferred_provider.class.sym, provider: preferred_provider)
    else
      # Redirect to the provider.
      redirect_to omniauth_authorize_path(:user, preferred_provider.class.sym, provider: preferred_provider)
    end
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

  def redirect_to_target!(user)
    redirect_to target_path(user)
  end

  # ==> Shorthands.

  def target_path(user)
    auth_target || after_sign_in_path_for(user)
  end

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

  def auth_redirect_params
    auth_hash.extra[:redirect_params].to_h || {}
  end

  def auth_target
    return nil if auth_hash.extra[:target].blank?

    "#{auth_hash.extra[:target]}?#{auth_redirect_params.to_param}"
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
    # Extract the provider from the authentication hash.
    return auth_hash.extra.provider if [Provider::Lti.sym, Provider::Saml.sym].include?(auth_provider_type)

    # Fallback to an oauth provider
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
