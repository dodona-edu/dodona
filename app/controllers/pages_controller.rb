class PagesController < ApplicationController
  def home
    @title = 'Home'
    @user = current_user
    redirect_to about_path if @user.nil?
  end

  def sign_in_page
    if params[:idp].present?
      session[:current_idp] = params[:idp]
      redirect_to new_user_session_url(idp: params[:idp])
    end
    @institutions = Institution.all
  end

  def institution_not_supported; end

  def about; end
end
