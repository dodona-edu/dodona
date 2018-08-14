require 'set'

class RepositoriesController < ApplicationController
  before_action :set_repository, only: %i[show edit update destroy hook reprocess]
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
    process_exercise_dirs if saved

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

  def hook
    success, msg = @repository.reset
    process_exercise_dirs if success
    status = success ? 200 : 500
    render plain: msg, status: status
  end

  def reprocess
    @repository.process_exercises
    redirect_to(@repository, notice: I18n.t('repositories.reprocess.done'))
  end

  private

  def process_exercise_dirs
    @repository.process_exercises
  rescue AggregatedConfigErrors => error
    if current_user
      ErrorMailer.json_error error, user: current_user
    elsif params[:pusher]
      pusher = params[:pusher]
      ErrorMailer.json_error error,
                             name: pusher[:name],
                             email: pusher[:email]
    else
      raise error
    end.deliver
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_repository
    @repository = Repository.find(params[:id])
    authorize @repository
  end
end
