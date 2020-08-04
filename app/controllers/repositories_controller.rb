require 'set'

class RepositoriesController < ApplicationController
  before_action :set_repository, only: %i[show edit update destroy media hook reprocess admins add_admin remove_admin courses add_course remove_course]

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
    @crumbs = [[I18n.t('repositories.index.title'), repositories_path], [@repository.name, '#']]
  end

  # GET /repositories/new
  def new
    authorize Repository
    @repository = Repository.new
    @title = I18n.t('repositories.new.title')
    @crumbs = [[I18n.t('repositories.index.title'), repositories_path], [I18n.t('repositories.new.title'), '#']]
  end

  # GET /repositories/1/edit
  def edit
    @title = @repository.name
    @crumbs = [[I18n.t('repositories.index.title'), repositories_path], [@repository.name, repository_path(@repository)], [I18n.t('crumbs.edit'), '#']]
  end

  # POST /repositories
  # POST /repositories.json
  def create
    authorize Repository
    @repository = Repository.new(permitted_attributes(Repository))
    saved = @repository.save
    if saved
      Event.create(event_type: :exercise_repository, user: current_user, message: "#{@repository.name} (id: #{@repository.id})")
      RepositoryAdmin.create(user_id: current_user.id, repository_id: @repository.id)
      @repository.delay.process_activities_email_errors(user: current_user)
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

  def media
    file = File.join(@repository.media_path, params[:media])
    raise ActionController::RoutingError, 'Not Found' unless File.file? file

    type = Mime::Type.lookup_by_extension File.extname(file)[1..]
    type = 'text/plain; charset=utf-8' if type.nil? || type == 'text/plain'

    # Support If-Modified-Since caching
    send_file file, disposition: 'inline', type: type \
      if stale? last_modified: File.mtime(file)
  end

  def admins
    @crumbs = [[I18n.t('repositories.index.title'), repositories_path], [@repository.name, repository_path(@repository)], [I18n.t('repositories.admins.admins'), '#']]
    @users = apply_scopes(@repository.admins)
             .order(last_name: :asc, first_name: :asc)
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
    payload = params.key?('payload') ? JSON.parse(params['payload']) : params
    unless success
      render plain: msg, status: :internal_server_error
      return
    end

    user_hash = {}
    do_reprocess = false
    if request.headers.key? 'X-GitHub-Event'
      if !payload.key?('commits') || payload['forced'] ||
         !payload['commits'].reject { |commit| commit['committer']['name'] == 'Dodona Server' }.empty?
        do_reprocess = true
        if current_user
          user_hash[:user] = current_user
        elsif payload.key?('pusher')
          pusher = payload['pusher']
          user_hash[:name] = pusher['name']
          user_hash[:email] = pusher['email']
        else
          user_hash[:user] = @repository.admins.first
        end
      end
    elsif request.headers.key? 'X-Gitlab-Event'
      # Gitlab doesn't tell us if the push was forced, so no fancy check if the reprocess is necessary.
      do_reprocess = true
      if current_user
        user_hash[:user] = current_user
      elsif payload.key?('user_name') && payload.key?('user_email')
        user_hash[:name] = payload['user_name']
        user_hash[:email] = payload['user_email']
      else
        user_hash[:user] = @repository.admins.first
      end
    else
      do_reprocess = true
      user_hash[:user] = @repository.admins.first
    end
    @repository.delay.process_activities_email_errors(user: user_hash[:user], name: user_hash[:name], email: user_hash[:email]) if do_reprocess

    render plain: msg, status: :ok
  end

  def reprocess
    @repository.process_activities_email_errors(user: current_user)
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
        toast = t('controllers.updated', model: model.model_name.human)
        format.json { head :no_content }
        format.js { render locals: { toast: toast } }
        format.html { redirect_to return_path, notice: toast }
      else
        alert = t('controllers.update_failed', model: model.model_name.human)
        format.json { head :unprocessable_entity }
        format.js { render status: :bad_request, locals: { toast: alert } }
        format.html { redirect_to return_path, alert: alert }
      end
    end
  end
end
