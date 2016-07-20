class ExercisesController < ApplicationController
  before_action :set_exercise, only: [:show, :edit, :update, :users, :media]

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to exercises_path, alert: "Sorry, we kunnen de oefening #{params[:name]} niet vinden."
  end

  def index
    authorize Exercise
    @exercises = policy_scope(Exercise).sort_by(&:name)
  end

  def show
    flash.now[:notice] = 'Deze oefening is niet toegankelijk voor studenten.' if @exercise.closed?
    flash.now[:notice] = 'Deze oefening is niet zichtbaar voor studenten.' if @exercise.hidden? && current_user && current_user.admin?
    @submissions = policy_scope(@exercise.submissions).paginate(page: params[:page])
  end

  def edit
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
