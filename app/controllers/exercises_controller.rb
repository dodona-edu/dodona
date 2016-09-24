class ExercisesController < ApplicationController
  before_action :set_exercise, only: [:show, :edit, :update, :users, :media]
  skip_before_action :verify_authenticity_token, only: [:media]

  has_scope :by_filter, as: 'filter'

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to exercises_path, alert: I18n.t('exercises.show.not_found')
  end

  def index
    authorize Exercise
    @exercises = policy_scope(Exercise).merge(apply_scopes(Exercise).all).order('name_' + I18n.locale.to_s).paginate(page: params[:page])
    @series = Series.find(params[:series_id]) if params[:series_id]
    @title = I18n.t('exercises.index.title')
  end

  def show
    flash.now[:notice] = I18n.t('exercises.show.not_accessible') if @exercise.closed?
    flash.now[:notice] = I18n.t('exercises.show.not_visible') if @exercise.hidden? && current_user && current_user.admin?
    @submissions = policy_scope(@exercise.submissions).paginate(page: params[:page])
    if params[:edit_submission]
      @edit_submission = Submission.find(params[:edit_submission])
      authorize @edit_submission, :edit?
    end
    @title = @exercise.name
  end

  def edit
    @title = @exercise.name
  end

  def update
    respond_to do |format|
      if @exercise.update(permitted_attributes(@exercise))
        format.html { redirect_to exercise_path(@exercise), flash: { success: I18n.t('controllers.updated', model: Exercise.model_name.human) } }
        format.json { render :show, status: :ok, location: @exercise }
      else
        format.html { render :edit }
        format.json { render json: @exercise.errors, status: :unprocessable_entity }
      end
    end
  end

  def users
    @users = User.all.order(last_name: :asc)
  end

  def media
    send_file File.join(@exercise.media_path, params[:media]), disposition: 'inline'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_exercise
    @exercise = Exercise.find(params[:id])
    authorize @exercise
  end
end
