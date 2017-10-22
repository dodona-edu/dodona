class ApiTokensController < ApplicationController
  before_action :set_user, except: %i[destroy]

  def index
    authorize ApiToken
    @tokens = ApiToken.where(user: @user)
  end

  def create
    authorize ApiToken
    @token = ApiToken.new(permitted_attributes(ApiToken))
    @token.user_id = params[:user_id]
    respond_to do |f|
      if @token.save
        f.html { redirect_back fallback_location: root_path, notice: I18n.t('controllers.created', model: ApiToken.model_name) }
      else
        f.html do
          redirect_back fallback_location: root_path,
                        alert: @token.errors.full_messages.join(', ')
        end
      end
    end
  end

  def destroy
    @token = ApiToken.find(params[:id])
    authorize @token
    @token.delete
    redirect_back fallback_location: root_path, notice: I18n.t('controllers.destroyed', model: ApiToken.model_name)
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
