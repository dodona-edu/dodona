class Auth::AuthenticationController < Devise::SessionsController
  # A sign-out route is inherited from the parent controller.

  has_scope :by_institution, as: 'institution_id'

  skip_before_action :verify_authenticity_token, raise: false

  def sign_in
    @providers = Provider.all
    @title = I18n.t('auth.sign_in.sign_in')
    @institution_providers = apply_scopes(@providers.where.not(type: Provider::Saml.name))
    render 'auth/sign_in'
  end
end
