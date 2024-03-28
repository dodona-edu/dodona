class ApiTokensController < ApplicationController
  before_action :set_user, except: %i[destroy]

  def index
    authorize @user, :list_tokens?
    @tokens = @user.api_tokens
  end

  def create
    authorize ApiToken
    @token = ApiToken.new(permitted_attributes(ApiToken))
    @token.user_id = params[:user_id]
    can_create = Pundit.policy!(current_user, @token.user).create_tokens?
    respond_to do |f|
      if can_create && @token.save
        message = I18n.t('controllers.created', model: ApiToken.model_name)
        f.html { redirect_back fallback_location: root_path, notice: message }
        f.js { render 'create', locals: { toast: message, new_token: @token } }
      else
        errors = @token.errors.full_messages
        errors << I18n.t('activerecord.errors.models.api_token.not_permitted') unless can_create
        message = errors.join(', ')
        f.html do
          redirect_back fallback_location: root_path,
                        alert: message
        end
        f.js { render 'toast', locals: { toast: message } }
      end
    end
  end

  def destroy
    @token = ApiToken.find(params[:id])
    authorize @token
    @user = current_user
    @token.delete
    respond_to do |f|
      message = I18n.t('controllers.destroyed', model: ApiToken.model_name)
      f.html do
        redirect_back fallback_location: root_path, notice: message
      end
      f.js do
        render 'delete', locals: { toast: message }
      end
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
