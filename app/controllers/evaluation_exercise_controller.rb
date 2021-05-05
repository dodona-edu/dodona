class EvaluationExerciseController < ApplicationController
  before_action :set_evaluation_exercise, only: %i[update]

  def update
    @evaluation_exercise.update!(permitted_attributes(@evaluation_exercise))
    respond_to do |format|
      format.js { render 'score_items/index', locals: { new: nil, evaluation_exercise: @evaluation_exercise } }
    end
  end

  private

  def set_evaluation_exercise
    @evaluation_exercise = EvaluationExercise.find(params[:id])
    @evaluation = @evaluation_exercise.evaluation
    authorize @evaluation, :update?
  end
end
