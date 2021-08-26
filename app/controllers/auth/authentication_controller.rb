class Auth::AuthenticationController < Devise::SessionsController
  # A sign-out route is inherited from the parent controller.

  has_scope :by_institution, as: 'institution_id'

  skip_before_action :verify_authenticity_token, raise: false

  def sign_in
    # Providers that are not necessarily specific to one institution.
    @generic_providers = {
      Provider::Smartschool => { image: 'smartschool.png', name: 'Smartschool' },
      Provider::Office365 => { image: 'office365.png', name: 'Office 365' },
      Provider::GSuite => { image: 'Google-logo.png', name: 'Google Workspace' }
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
      .where(institutions: { generated_name: false }))
    render 'auth/sign_in'
  end
end
