class PagesController < ApplicationController
  def home
    @title = 'Home'
    @user = current_user
  end

  def sign_in_page
    if params[:idp].present?
      session[:current_idp] = params[:idp]
      redirect_to new_user_session_url(idp: params[:idp])
    end
    @institutions = Institution.all
  end
end
