require 'set'

class RepositoriesController < ApplicationController
  before_action :set_repository, only: [:show, :edit, :update, :destroy, :hook, :reprocess]
  skip_before_action :verify_authenticity_token, only: [:hook]

  # GET /repositories
  # GET /repositories.json
  def index
    authorize Repository
    @repositories = Repository.all
  end

  # GET /repositories/1
  # GET /repositories/1.json
  def show
  end

  # GET /repositories/new
  def new
    authorize Repository
    @repository = Repository.new
  end

  # GET /repositories/1/edit
  def edit
  end

  # POST /repositories
  # POST /repositories.json
  def create
    authorize Repository
    @repository = Repository.new(permitted_attributes(Repository))
    saved = @repository.save
    Exercise.process_repository @repository if saved

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
    success, msg = @repository.pull
    if success
      if params.key?('commits')
        exercises = Set.new
        params['commits'].each do |commit|
          next if commit['author']['name'] == 'Dodona'
          %w(added removed modified).each do |type|
            commit[type].each do |file|
              dirs = file.split('/').reverse
              path = '/' + dirs.pop
              until Exercise.exercise_directory?(@repository, path) || dirs.empty?
                path = File.join(path, dirs.pop)
              end
              exercises.add(path) unless dirs.empty?
            end
          end
        end
        Exercise.process_directories @repository, exercises.to_a
      else
        Exercise.process_repository @repository
      end
    end
    status = success ? 200 : 500
    render plain: msg, status: status
  end

  def reprocess
    Exercise.process_repository @repository
    redirect_to(@repository, notice: I18n.t('repositories.reprocess.done'))
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_repository
    @repository = Repository.find(params[:id])
    authorize @repository
  end
end
