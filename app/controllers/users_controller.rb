class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy impersonate token_sign_in]
  before_action :set_users, only: %i[index available_for_repository]

  has_scope :by_permission
  has_scope :by_institution, as: 'institution_id'
  has_scope :by_filter, as: 'filter'

  # GET /users
  # GET /users.json
  def index
    @title = I18n.t('users.index.title')
  end

  def available_for_repository
    @repository = Repository.find(params[:repository_id]) if params[:repository_id]
    respond_to do |format|
      format.html { redirect_to @repository }
      format.json { render :available_for_repository }
      format.js { render :available_for_repository }
    end
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
    @crumbs = [[I18n.t('users.index.title'), users_path], [I18n.t('users.new.title'), '#']]
  end

  # GET /users/1/edit
  def edit
    @title = @user.full_name
    @crumbs = [[@user.full_name, user_path(@user)], [I18n.t('crumbs.edit'), '#']]
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
    if token.present? && token == @user.token
      sign_in(@user)
      @user.touch(:sign_in_at)
    end
    redirect_to root_path
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
    authorize @user
  end

  def set_users
    authorize User
    @users = apply_scopes(User).all.order(permission: :desc, last_name: :asc, first_name: :asc).paginate(page: parse_pagination_param(params[:page]))
  end
end
