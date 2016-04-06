class ExercisesController < ApplicationController

  def index
    @exercises = Exercise.all
  end

end
