class Auth::RedirectController < ApplicationController

  layout 'embedded'

  def redirect
    @path = users_lti_do_redirect_path(sym: params[:sym], provider: params[:provider])
    @browser_path = users_lti_do_redirect_path(sym: params[:sym], provider: params[:provider], browser: true)
    session[:manual_redirect] = true

    render 'auth/redirect'
  end

  def do_redirect
    if session[:manual_redirect]
      # This is the first we hit this path, so redirect to the provider.
      unless params[:browser]
        # If we were called in an iframe, don't redirect at the end of the process.
        session.delete(:original_redirect)
        session[:hide_flash] = true
      end
      session.delete(:manual_redirect)
      redirect_to omniauth_authorize_path(:user, params[:sym], provider: params[:provider])
    else
      # This is the second time we hit this path, as the redirect from the main provider.
      if session[:original_redirect]
        # We have a saved original target, so we are not in an iframe.
        original = session[:original_redirect]
        session.delete(:original_redirect)
        redirect_to original
      else
        # We are in an iframe, so tell the user that they should close the page.
        render 'auth/redirected'
      end
    end
  end
end
