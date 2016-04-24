class ExercisesController < ApplicationController
  def index
    @exercises = Exercise.all.sort_by(&:name)
  end

  def show
    @exercise = Exercise.find_by_name(params[:name])
    if @exercise.nil?
      redirect_to exercises_path, alert: "Sorry, we kunnen de oefening #{params[:name]} niet vinden."
    end
  end
end
