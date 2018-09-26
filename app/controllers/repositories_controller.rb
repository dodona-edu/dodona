require 'set'

class RepositoriesController < ApplicationController
  before_action :set_repository, only: %i[show edit update destroy hook reprocess admins add_admin remove_admin courses add_course remove_course]
  skip_before_action :verify_authenticity_token, only: [:hook]

  # GET /repositories
  # GET /repositories.json
  def index
    authorize Repository
    @repositories = Repository.all
    @title = I18n.t('repositories.index.title')
  end

  # GET /repositories/1
  # GET /repositories/1.json
  def show
    @title = @repository.name
    @crumbs = [[I18n.t('repositories.index.title'), repositories_path], [@repository.name, "#"]]
  end

  # GET /repositories/new
  def new
    authorize Repository
    @repository = Repository.new
    @title = I18n.t('repositories.new.title')
    @crumbs = [[I18n.t('repositories.index.title'), repositories_path], [I18n.t('repositories.new.title'), "#"]]
  end

  # GET /repositories/1/edit
  def edit
    @title = @repository.name
    @crumbs = [[I18n.t('repositories.index.title'), repositories_path], [@repository.name, repository_path(@repository)], [I18n.t("crumbs.edit"), "#"]]
  end

  # POST /repositories
  # POST /repositories.json
  def create
    authorize Repository
    @repository = Repository.new(permitted_attributes(Repository))
    saved = @repository.save
    if saved
      RepositoryAdmin.create(user_id: current_user.id, repository_id: @repository.id)
      @repository.process_exercises
    end

    respond_to do |format|
      if saved
        format.html { redirect_to @repository, notice: I18n.t('controllers.created', model: Repository.model_name.human) }
        format.json { render :show, status: :created, location: @repository }
      else
        format.html { render :new }
        format.json { render json: @repository.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /repositories/1
  # PATCH/PUT /repositories/1.json
  def update
    respond_to do |format|
      if @repository.update(permitted_attributes(Repository))
        format.html { redirect_to @repository, notice: I18n.t('controllers.updated', model: Repository.model_name.human) }
        format.json { render :show, status: :ok, location: @repository }
      else
        format.html { render :edit }
        format.json { render json: @repository.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /repositories/1
  # DELETE /repositories/1.json
  def destroy
    @repository.destroy
    respond_to do |format|
      format.html { redirect_to repositories_url, notice: I18n.t('controllers.destroyed', model: Repository.model_name.human) }
      format.json { head :no_content }
    end
  end

  def admins
    @crumbs = [[I18n.t('repositories.index.title'), repositories_path], [@repository.name, repository_path(@repository)], [I18n.t('repositories.admins.admins'), '#']]
    @users = apply_scopes(@repository.admins)
             .order(username: :asc)
             .paginate(page: params[:page])
  end

  def add_admin
    success = RepositoryAdmin.create(repository_id: @repository.id, user_id: params[:user_id])
    model_update_response success, RepositoryAdmin, admins_repository_path(@repository)
  end

  def remove_admin
    success = RepositoryAdmin.find_by(repository_id: @repository.id, user_id: params[:user_id])&.destroy
    model_update_response success, RepositoryAdmin, admins_repository_path(@repository)
  end

  def courses
    @crumbs = [[I18n.t('repositories.index.title'), repositories_path], [@repository.name, repository_path(@repository)], [I18n.t('repositories.courses.courses'), '#']]
    @courses = apply_scopes(@repository.allowed_courses)
               .order(year: :desc, name: :asc)
  end

  def add_course
    success = CourseRepository.create(repository_id: @repository.id, course_id: params[:course_id])
    model_update_response success, CourseRepository, courses_repository_path(@repository)
  end

  def remove_course
    success = CourseRepository.find_by(repository_id: @repository.id, course_id: params[:course_id])&.destroy
    model_update_response success, CourseRepository, courses_repository_path(@repository)
  end

  def hook
    success, msg = @repository.reset
    if success
      if !params.key?('commits') || params['forced'] ||
         !params['commits'].reject {|commit| commit['author']['name'] == 'Dodona'}.empty?
        if current_user
          @repository.delay.process_exercises_email_errors(user: current_user)
        elsif params['pusher']
          pusher = params['pusher']
          @repository.delay.process_exercises_email_errors(name: pusher['name'], email: pusher['email'])
        else
          @repository.delay.process_exercises
        end
      end
    end
    status = success ? 200 : 500
    render plain: msg, status: status
  end

  def reprocess
    @repository.process_exercises_email_errors(user: current_user)
    redirect_to(@repository, notice: I18n.t('repositories.reprocess.done'))
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_repository
    @repository = Repository.find(params[:id])
    authorize @repository
  end

  def model_update_response(success, model, return_path)
    respond_to do |format|
      if success
        notification = t('controllers.updated', model: model.model_name.human)
        format.json { head :no_content }
        format.js { render locals: {notification: notification } }
        format.html { redirect_to return_path, notice: notification }
      else
        alert = t('controllers.update_failed', model: model.model_name.human)
        format.json { head :unprocessable_entity }
        format.js { render status: 400, locals: { notification: alert } }
        format.html { redirect_to return_path, alert: alert }
      end
    end
  end
end
