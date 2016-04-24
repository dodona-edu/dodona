class ExercisesController < ApplicationController
  before_action :set_exercise, only: [:show]

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to exercises_path, alert: "Sorry, we kunnen de oefening #{params[:name]} niet vinden."
  end

  def index
    authorize Exercise
    @exercises = policy_scope(Exercise).sort_by(&:name)
  end

  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_exercise
    @exercise = Exercise.find_by_name(params[:name])
    fail ActiveRecord::RecordNotFound if @exercise.nil?
    authorize @exercise
  end
end
