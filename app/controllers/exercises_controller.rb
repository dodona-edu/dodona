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
    if params[:series_id]
      @series = Series.find(params[:series_id])
    end
  end

  def show
    # Check token for hidden exercises
    if @exercise.hidden? && @exercise.exercise_token.token != params[:token]
      authorize @exercise, :show_hidden_without_token?
    end

    flash.now[:notice] = I18n.t('exercises.show.not_accessible') if @exercise.closed?
    if @exercise.hidden? && current_user && current_user.admin?
      url = exercise_url(@exercise, token: @exercise.exercise_token.token)
      path = exercise_path(@exercise, token: @exercise.exercise_token.token)
      link = view_context.link_to url, path
      flash.now[:notice] = I18n.t('exercises.show.not_visible', link: link).html_safe
    end
    @submissions = policy_scope(@exercise.submissions).paginate(page: params[:page])
    if params[:edit_submission]
      @edit_submission = Submission.find(params[:edit_submission])
      authorize @edit_submission, :edit?
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @exercise.update(permitted_attributes(@exercise))
        puts "HEY HEY HEY"
        puts @exercise.inspect
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
