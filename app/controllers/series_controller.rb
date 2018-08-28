require 'zip'
class SeriesController < ApplicationController
  before_action :set_series, except: %i[index new create indianio_download]

  before_action :check_token, only: %i[show overview download_solutions]

  # GET /series
  # GET /series.json
  def index
    authorize Series
    @series = policy_scope(Series)
    @title = I18n.t('series.index.title')
  end

  # GET /series/1
  # GET /series/1.json
  def show
    @course = @series.course
    @title = @series.name
    @crumbs = [[@course.name, course_path(@course)], [@series.name, "#"]]
  end

  def overview
    @title = "#{@series.course.name} #{@series.name}"
    @course = @series.course
    @crumbs = [[@course.name, course_path(@course)], [@series.name, series_path(@series)], [I18n.t("crumbs.overview"), "#"]]
  end

  # GET /series/new
  def new
    course = Maybe(params[:course_id])
             .map { |cid| Course.find_by id: cid }
             .or_nil
    authorize course, :add_series?
    @series = Series.new
    @title = I18n.t('series.new.title')
    @crumbs = [[course.name, course_path(course)], [I18n.t('series.new.title'), "#"]]
  end

  # GET /series/1/edit
  def edit
    @title = @series.name
    @crumbs = [[@series.course.name, course_path(@series.course)], [@series.name, series_path(@series)], [I18n.t("crumbs.edit"), "#"]]
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
    send_zip current_user
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
        render status: 403
        return
      end
    end
    SeriesMembership.create(series: @series, exercise: @exercise)
  end

  def remove_exercise
    @exercise = Exercise.find(params[:exercise_id])
    @series.exercises.delete(@exercise)
  end

  def reorder_exercises
    order = JSON.parse(params[:order])
    @series.series_memberships.each do |membership|
      rank = order.find_index(membership.exercise_id) || 999
      membership.update(order: rank)
    end
  end

  def scoresheet
    @course = @series.course
    @title = @series.name
    @exercises = @series.exercises
    @crumbs = [[@course.name, course_path(@course)], [@series.name, series_path(@series)], [I18n.t("crumbs.overview"), "#"]]
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
    raise Pundit::NotAuthorizedError if
      @series.hidden? &&
      !current_user&.course_admin?(@series.course) &&
      @series.access_token != params[:token]
  end

  # Generate and send a zip with solutions
  def send_zip(user, **opts)
    zip = @series.zip_solutions(user, opts)
    send_data zip[:data],
              type: 'application/zip',
              filename: zip[:filename],
              disposition: 'attachment', x_sendfile: true
  end
end
