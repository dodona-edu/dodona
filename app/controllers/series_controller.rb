require 'zip'
class SeriesController < ApplicationController
  before_action :set_series, only: [:show, :edit, :update, :destroy, :add_exercise, :remove_exercise, :reorder_exercises, :download_solutions, :token_show, :scoresheet]

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

  def token_show
    raise Pundit::NotAuthorizedError if @series.token != params[:token]

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
        format.html { redirect_to course_path(@series.course, anchor: "series-#{@series.name.parameterize}"), notice: I18n.t('controllers.updated', model: Series.model_name.human) }
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
    @series.destroy
    respond_to do |format|
      format.html { redirect_to series_url, notice: I18n.t('controllers.destroyed', model: Series.model_name.human) }
      format.json { head :no_content }
    end
  end

  def download_solutions
    zip = @series.zip_solutions(current_user, with_info: current_user.admin? || true_user.admin?)
    send_data(zip[:data], type: 'application/zip', filename: zip[:filename], disposition: 'attachment', x_sendfile: true)
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

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_series
    @series = Series.find(params[:id])
    authorize @series
  end
end
