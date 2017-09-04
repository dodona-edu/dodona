require 'zip'
class SeriesController < ApplicationController
  before_action :set_series, except: %i[index new create indianio_download]

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
  end

  def overview; end

  def token_show
    raise Pundit::NotAuthorizedError if @series.access_token != params[:token]

    @course = @series.course
    @title = @series.name
    render 'show'
  end

  # GET /series/new
  def new
    authorize Series
    @series = Series.new
    @title = I18n.t('series.new.title')
  end

  # GET /series/1/edit
  def edit
    @title = @series.name
  end

  # POST /series
  # POST /series.json
  def create
    authorize Series
    @series = Series.new(permitted_attributes(Series))

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
      if @series.update(permitted_attributes(Series))
        format.html { redirect_to course_path(@series.course, all: true, anchor: "series-#{@series.name.parameterize}"), notice: I18n.t('controllers.updated', model: Series.model_name.human) }
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

  def update_token
    type = params[:type].to_sym
    @series.generate_token(type)
    @series.save
    value =
      case type
      when :indianio_token
        @series.indianio_token
      when :access_token
        token_show_series_url(@series, @series.access_token)
      end
    render partial: 'token_field', locals: {
      type: type,
      value: value
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

  # Generate and send a zip with solutions
  def send_zip(user, **opts)
    zip = @series.zip_solutions(user, opts)
    send_data zip[:data],
              type: 'application/zip',
              filename: zip[:filename],
              disposition: 'attachment', x_sendfile: true
  end
end
