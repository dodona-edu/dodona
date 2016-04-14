class ExercisesController < ApplicationController
  def index
    @exercises = Exercise.all.sort_by(&:name)
  end

  def show
    @exercise = Exercise.find(params[:id])
    if @exercise.nil?
      redirect_to exercises_path, alert: "Sorry, we kunnen de oefening #{params[:id]} niet vinden."
    end
  end
end
