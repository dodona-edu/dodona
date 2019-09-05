require 'zip'
class SeriesController < ApplicationController
  before_action :set_series, except: %i[index new create indianio_download]

  before_action :check_token, only: %i[show overview download_solutions]

  has_scope :at_least_one_started, type: :boolean, only: :scoresheet do |controller, scope|
    scope.at_least_one_started(Series.find(controller.params[:id]))
  end
  has_scope :by_course_labels, as: 'course_labels', type: :array, only: :scoresheet do |controller, scope, value|
    scope.by_course_labels(value, Series.find(controller.params[:id]).course_id)
  end
  has_scope :by_filter, as: 'filter', only: :scoresheet

  # GET /series
  # GET /series.json
  def index
    authorize Series
    @course = Course.find(params[:course_id])
    @series = policy_scope(@course.series)
    @title = I18n.t('series.index.title')
  end

  # GET /series/1
  # GET /series/1.json
  def show
    @course = @series.course
    @title = @series.name
    @crumbs = [[@course.name, course_path(@course)], [@series.name, '#']]
    @user = User.find(params[:user_id]) if params[:user_id] && current_user&.course_admin?(@course)
  end

  def overview
    @title = "#{@series.course.name} #{@series.name}"
    @course = @series.course
    @crumbs = [[@course.name, course_path(@course)], [@series.name, course_path(@series.course, anchor: @series.anchor)], [I18n.t('crumbs.overview'), '#']]
    @user = User.find(params[:user_id]) if params[:user_id] && current_user&.course_admin?(@course)
  end

  # GET /series/new
  def new
    course = Maybe(params[:course_id])
             .map { |cid| Course.find_by id: cid }
             .or_nil
    authorize course, :add_series?
    @series = Series.new(course: course)
    @title = I18n.t('series.new.title')
    @crumbs = [[course.name, course_path(course)], [I18n.t('series.new.title'), '#']]
  end

  # GET /series/1/edit
  def edit
    @title = @series.name
    @crumbs = [[@series.course.name, course_path(@series.course)], [@series.name, course_path(@series.course, anchor: @series.anchor)], [I18n.t('crumbs.edit'), '#']]
    @labels = policy_scope(Label.all)
    @programming_languages = policy_scope(ProgrammingLanguage.all)
    @repositories = policy_scope(Repository.all)
  end

  # POST /series
  # POST /series.json
  def create
    @series = Series.new(permitted_attributes(Series))
    authorize @series.course, :add_series?
    respond_to do |format|
      if @series.save
        format.html { redirect_to edit_series_path(@series), notice: I18n.t('controllers.created', model: Series.model_name.human) }
        format.json { render :show, status: :created, location: @series }
      else
        format.html { render :new }
        format.json { render json: @series.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /series/1
  # PATCH/PUT /series/1.json
  def update
    respond_to do |format|
      if @series.update(permitted_attributes(@series))
        format.html { redirect_to course_path(@series.course, series: @series, anchor: @series.anchor), notice: I18n.t('controllers.updated', model: Series.model_name.human) }
        format.json { render :show, status: :ok, location: @series }
      else
        format.html { render :edit }
        format.json { render json: @series.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /series/1
  # DELETE /series/1.json
  def destroy
    course = @series.course
    @series.destroy
    respond_to do |format|
      format.html { redirect_to course_url(course), notice: I18n.t('controllers.destroyed', model: Series.model_name.human) }
      format.json { head :no_content }
    end
  end

  def download_solutions
    if current_user&.course_admin?(@series.course)
      if params[:user_id].present?
        send_zip User.find(params[:user_id])
      else
        send_zip nil
      end
    else
      send_zip current_user
    end
  end

  def reset_token
    type = params[:type].to_sym
    @series.generate_token(type)
    @series.save
    value =
      case type
      when :indianio_token
        @series.indianio_token
      when :access_token
        series_url(@series, token: @series.access_token)
      end
    render partial: 'application/token_field', locals: {
      container_name: :access_token_field,
      name: type,
      value: value,
      reset_url: reset_token_series_path(@series, type: type)
    }
  end

  def indianio_download
    token = params[:token]
    email = params[:email]
    @series = Series.find_by(indianio_token: token)
    if token.blank? || @series.nil?
      render json: { errors: ['Wrong token'] }, status: :unauthorized
    elsif email.blank?
      render json: { errors: ['No email given'] }, status: :unprocessable_entity
    else
      user = User.find_by(email: email)
      if user
        send_zip user, with_info: true
      else
        render json: { errors: ['Unknown email'] }, status: :not_found
      end
    end
  end

  def add_exercise
    @exercise = Exercise.find(params[:exercise_id])
    unless @exercise.usable_by? @series.course
      if current_user.repository_admin? @exercise.repository
        @series.course.usable_repositories << @exercise.repository
      else
        render status: :forbidden
        return
      end
    end
    SeriesMembership.create(series: @series, exercise: @exercise)
  end

  def remove_exercise
    @exercise = Exercise.find(params[:exercise_id])
    @series.exercises.destroy(@exercise)
  end

  def reorder_exercises
    order = JSON.parse(params[:order])
    @series.series_memberships.each do |membership|
      rank = order.find_index(membership.exercise_id) || 0
      membership.update(order: rank)
    end
  end

  def scoresheet
    @course = @series.course
    @title = @series.name
    @exercises = @series.exercises
    @users = apply_scopes(@course.enrolled_members)
    @course_labels = CourseLabel.where(course: @course)
    @submission_hash = Submission.in_series(@series).where(user: @users)
    @submission_hash = @submission_hash.before_deadline(@series.deadline) if @series.deadline.present?
    @submission_hash = @submission_hash.group(%i[user_id exercise_id]).most_recent.map { |s| [[s.user_id, s.exercise_id], s] }.to_h
    @crumbs = [[@course.name, course_path(@course)], [@series.name, course_path(@series.course, anchor: @series.anchor)], [I18n.t('crumbs.overview'), '#']]
  end

  def scoresheet_download
  end

  def mass_rejudge
    @submissions = Submission.in_series(@series)
    Submission.rejudge(@submissions)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_series
    @series = Series.find(params[:id])
    authorize @series
  end

  def check_token
    raise Pundit::NotAuthorizedError if @series.hidden? &&
                                        !current_user&.course_admin?(@series.course) &&
                                        @series.access_token != params[:token]
  end

  # Generate and send a zip with solutions
  def send_zip(user, **opts)
    zip = if user.present?
            @series.zip_solutions_for_user(user, opts)
          else
            @series.zip_solutions(opts)
          end
    send_data zip[:data],
              type: 'application/zip',
              filename: zip[:filename],
              disposition: 'attachment', x_sendfile: true
  end
end
