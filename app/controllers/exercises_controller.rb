class ExercisesController < ApplicationController
  before_action :set_exercise, only: [:show, :edit, :update, :users]

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
        format.html { redirect_to exercise_path(@exercise.name), flash: { success: 'De oefening werd succesvol aangepast.' } }
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

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_exercise
    @exercise = Exercise.find_by_name(params[:name])
    raise ActiveRecord::RecordNotFound if @exercise.nil?
    authorize @exercise
  end
end
