class Auth::AuthenticationController < Devise::SessionsController
  # A sign-out route is inherited from the parent controller.

  has_scope :by_institution, as: 'institution_id'

  skip_before_action :verify_authenticity_token, raise: false

  def sign_in
    # Providers that are not necessarily specific to one institution.
    @generic_providers = {
      Provider::Smartschool => { image: 'smartschool.png', name: 'Smartschool' },
      Provider::Office365 => { image: 'office365.png', name: 'Office 365' },
      Provider::GSuite => { image: 'google_oauth2.png', name: 'G Suite' }
    }

    # Calculate some information for these providers.
    @generic_providers.each do |key, value|
      value[:link] = omniauth_authorize_path(:user, key.sym)
    end

    @providers = Provider.all
    @title = I18n.t('auth.sign_in.sign_in')
    @oauth_providers = apply_scopes(@providers
      .includes(:institution)
      .where(type: @generic_providers.keys)
      .where(mode: :prefer)
      .where.not(institutions: { name: Institution::NEW_INSTITUTION_NAME }))
    render 'auth/sign_in'
  end
end
