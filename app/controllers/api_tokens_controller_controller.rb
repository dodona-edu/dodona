class ApiTokensController < ApplicationController
  before_action :set_user, except: %i[destroy]

  def index
    authorize ApiToken
    @tokens = ApiToken.where(user: @user)
  end

  def create
    authorize ApiToken
    @token = ApiToke.new(permitted_attributes(ApiToken))
  end

  def destroy
    @token = ApiToken.find(params[:id])
    authorize @token
    @token.delete
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
