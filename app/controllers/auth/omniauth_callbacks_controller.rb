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

  def oidc
    try_login!
  end

  def surf
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

    identity = nil
    # First try to find an existing identity
    if auth_uid.present?
      # Basic case
      identity = find_identity_by_uid
    else
      # For providers without auth uid
      user = find_user_in_institution
      identity = find_identity_by_user(user) if user.present?
    end
    # At this point identity should have a value if it exists in our database

    if identity.blank?
      # If no identity was found and the provider is a link provider, prompt the
      # user to sign in with a preferred provider.
      return redirect_to_preferred_provider! if provider.link?

      # If no identity exist, we want to check if it is a new user or an existing user using a new provider
      # Try to find an existing user
      user = find_user_in_institution
      # If we found an existing user, which already has an identity for this provider
      # This will require a manual intervention by the development team, notify the user and the team
      return redirect_with_flash!('TODO') if user&.providers&.find(id: provider.id).present?
      # If we found an existing user with the same username or email
      # We will ask the user to verify if this was the user they wanted to sign in to
      # if yes => redirect to a previously used provider for this user
      # if no => contact dodona for a manual intervention
      return redirect_to_known_provider!(user) if user.present?

      # No existing user was found
      # Create a new user
      user = User.new institution: provider&.institution
      # Create a new identity for the newly created user
      identity = user.identities.build identifier: auth_uid, provider: provider
    end

    # Validation.
    raise 'Identity should not be nil here' if identity.nil?

    # Get the user independent of it being newly created or an existing user
    user = identity.user
    # Update the user information from the authentication response.
    user.update_from_provider(auth_hash, provider)
    return redirect_with_errors!(user) if user.errors.any?

    # If the session contains credentials for another identity, add this identity to the signed in user
    create_identity_from_session!(user)

    # User successfully updated, finish the authentication procedure. Force is
    # required to overwrite the current existing user.
    sign_in user, event: :authentication, force: true

    # Redirect the user to their destination.
    redirect_to_target!(user)
  end

  # ==> Utilities.

  def create_identity_from_session!(user)
    # Find the original provider and uid in the session.
    original_provider_id = session.delete(:auth_original_provider_id)
    original_uid = session.delete(:auth_original_uid)
    return if original_provider_id.blank? || original_uid.blank?

    # If a userid was specified in the session, only create a new identity if that user signed in
    original_user_id = session.delete(:auth_original_user_id)
    return if original_user_id.present? && user.id != original_user_id

    # Find the actual provider.
    original_provider = Provider.find(original_provider_id)
    return if original_provider.blank?

    # Create the identity for the current user.
    Identity.create(identifier: original_uid, provider: original_provider, user: user)

    if session[:hide_flash].blank?
      # Set a flash message.
      set_flash_message :notice, :identity_created, provider: original_provider.class.sym.to_s
    end
    session.delete(:hide_flash)
  end

  def find_identity_by_uid
    # In case of provider without uids, don't return any identity (As it won't be matching a unique user)
    Identity.find_by(identifier: auth_uid, provider: provider) if auth_uid.present?
  end

  def find_identity_by_user(user)
    Identity.find_by(provider: provider, user: user)
  end

  def find_user_in_institution
    # Attempt to find user by its username and institution id
    user = User.from_username_and_institution(auth_uid, provider.institution_id)
    # Try to find the user using the email address and institution id.
    user = User.from_email_and_institution(auth_email, provider.institution_id) if user.blank?
    user
  end

  def find_or_create_oauth_provider
    # Find an existing provider.
    provider_type = Provider.for_sym(auth_provider_type)
    provider = provider_type.find_by(identifier: oauth_provider_id)
    return provider if provider.present?

    # Provider was not found. Currently, a new institution will be created for
    # every new provider as well.
    name, short_name = provider_type.extract_institution_name(auth_hash)
    institution = Institution.new name: name,
                                  short_name: short_name,
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
    set_flash_message :alert, :failure, kind: provider_type, reason: reason
    flash[:options] = [{ url: contact_path, message: I18n.t('pages.contact.prompt') }]
  end

  def store_identity_in_session!
    # Store the uid and the id of the current provider in the session, to link
    # the identities after returning.
    session[:auth_original_provider_id] = provider.id unless provider.redirect?
    session[:auth_original_uid] = auth_uid unless provider.redirect?
  end

  def redirect_to_provider!(target_provider)
    store_identity_in_session!

    # If this is the first time a user is logging in with LTI, we do something special: LTI
    # related screens are often shown inside an iframe, which some providers don't support
    # (for example, UGent SAML doesn't).
    # We try our best to detect an iframe with the Sec-Fetch-Dest header, but at the time of
    # writing, Firefox and Safari don't support it.
    if auth_provider_type == Provider::Lti.sym && request.headers['Sec-Fetch-Dest'] != 'document'
      # The header is nil, in which case we don't know if it is an iframe or not, or the header is
      # "iframe", in which case we do know it is an iframe.
      # Anyway, we save the original target, and redirect to a web page.
      # We are not saving the entire URL, since this can be lengthy
      # and cause problems overflowing the session.
      session[:original_redirect] = URI.parse(target_path(:user)).path
      redirect_to lti_redirect_path(sym: target_provider.class.sym, provider: target_provider)
    else
      # Redirect to the provider.
      redirect_to omniauth_authorize_path(:user, target_provider.class.sym, provider: target_provider)
    end
  end

  def redirect_to_preferred_provider!
    # Find the preferred provider for the current institution.
    preferred_provider = provider.institution.preferred_provider
    redirect_to_provider!(preferred_provider)
  end

  def redirect_with_errors!(resource)
    logger.info "User was unable to login because of reason: '#{resource.errors.full_messages.to_sentence}'. More info about the request below:\n" \
                "#{auth_hash.pretty_inspect}"

    ApplicationMailer.with(authinfo: auth_hash, errors: resource.errors.inspect)
                     .user_unable_to_log_in
                     .deliver_later

    first_error = resource.errors.first
    if first_error.attribute == :institution && first_error.type.to_s == 'must be unique'
      flash_wrong_provider provider, resource.identities.first.provider
      redirect_to root_path
    else
      redirect_with_flash! resource.errors.full_messages.to_sentence
    end
  end

  def redirect_with_flash!(message)
    flash_failure message
    redirect_to root_path
  end

  def redirect_to_known_provider!(user)
    store_identity_in_session!
    session[:auth_original_user_id] = user.id
    known_providers = user.providers.where(mode: %i[prefer secondary])
    set_flash_message :alert, :redirect_to_known_provider, user: user.name, username: user.username, email: user.email, institution: user.institution.name
    flash[:options] = known_providers.map do |known_provider|
      {
        message: I18n.t('devise.omniauth_callbacks.redirect_to_known_provider_option', provider: known_provider.class.sym.to_s),
        url: omniauth_authorize_path(:user, known_provider.class.sym, provider: known_provider)
      }
    end
    flash[:options] << { url: contact_path, message: I18n.t('devise.omniauth_callbacks.redirect_to_known_provider_contact') }
    redirect_to root_path
  end

  def flash_wrong_provider(tried_provider, user_provider)
    set_flash_message :alert, :wrong_provider,
                      tried_email_address: auth_email,
                      tried_provider_type: tried_provider.class.sym.to_s,
                      tried_provider_institution: tried_provider.institution.name,
                      user_provider_type: user_provider.class.sym.to_s,
                      user_institution: user_provider.institution.name
    flash[:options] = [{ message: I18n.t('devise.omniauth_callbacks.wrong_provider_extra', user_provider_type: user_provider.class.sym.to_s), url: omniauth_authorize_path(:user, user_provider.class.sym, provider: user_provider) }]
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
