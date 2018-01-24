class PagesController < ApplicationController
  def home
    @title = 'Home'
    @user = current_user
  end

  def sign_in
    @institutions = Institution.all
  end
end
