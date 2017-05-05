class PagesController < ApplicationController
  def home
    @title = 'Home'
    @user = current_user
  end
end
