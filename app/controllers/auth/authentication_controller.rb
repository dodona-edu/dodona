class Auth::AuthenticationController < Devise::SessionsController
  # A sign-out route is inherited from the parent controller.

  skip_before_action :verify_authenticity_token, raise: false

  def sign_in
    @providers = Provider.all
    @title = I18n.t('auth.sign_in.sign_in')

    render 'auth/sign_in'
  end
end
