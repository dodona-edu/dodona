class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy impersonate photo token_sign_in]

  has_scope :by_permission
  has_scope :by_name, as: 'filter'

  # GET /users
  # GET /users.json
  def index
    authorize User
    @users = apply_scopes(User).all.order(permission: :desc, username: :asc).paginate(page: params[:page])
    @title = I18n.t('users.index.title')
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @title = @user.full_name
  end

  # GET /users/new
  def new
    authorize User
    @user = User.new
    @title = I18n.t('users.new.title')
  end

  # GET /users/1/edit
  def edit
    @title = @user.full_name
  end

  # POST /users
  # POST /users.json
  def create
    authorize User
    @user = User.new(permitted_attributes(User))

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, flash: { success: I18n.t('controllers.created', model: User.model_name.human) } }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(permitted_attributes(@user))
        format.html { redirect_to @user, notice: I18n.t('controllers.updated', model: User.model_name.human) }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: I18n.t('controllers.destroyed', model: User.model_name.human) }
      format.json { head :no_content }
    end
  end

  def photo
    file = @user.photo || User.default_photo
    send_file file, disposition: 'inline'
  end

  def impersonate
    impersonate_user(@user)
    redirect_to root_path
  end

  def stop_impersonating
    authorize User
    stop_impersonating_user
    redirect_back(fallback_location: root_path)
  end

  def token_sign_in
    token = params[:token]
    sign_in(@user) if token.present? && token == @user.token
    redirect_to root_path
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
    authorize @user
  end
end
