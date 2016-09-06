class SeriesController < ApplicationController
  before_action :set_series, only: [:show, :edit, :update, :destroy, :add_exercise, :remove_exercise, :reorder_exercises]

  # GET /series
  # GET /series.json
  def index
    authorize Series
    @series = policy_scope(Series)
  end

  # GET /series/1
  # GET /series/1.json
  def show
    @course = @series.course
  end

  # GET /series/new
  def new
    authorize Series
    @series = Series.new
  end

  # GET /series/1/edit
  def edit
    @exercises = policy_scope(Exercise).order('name_' + I18n.locale.to_s).paginate(page: params[:page])
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
        format.html { redirect_to @series.course, notice: I18n.t('controllers.updated', model: Series.model_name.human) }
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

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_series
    @series = Series.find(params[:id])
    authorize @series
  end
end
