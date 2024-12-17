class EvaluationExerciseController < ApplicationController
  before_action :set_evaluation_exercise, only: %i[update]

  def update
    @evaluation_exercise.update!(permitted_attributes(@evaluation_exercise))

    if params[:evaluation_exercise].key?(:score_items)
      score_items = params[:evaluation_exercise][:score_items]
      ScoreItem.transaction do
        new_items = score_items.filter { |item| !item.key?(:id) || item[:id].blank? }
        updated_items = score_items.filter { |item| item[:id].present? }
        @evaluation_exercise.score_items.each do |item|
          if (updated_item = updated_items.find { |i| i[:id].to_i == item.id })
            item.update!(updated_item.permit(:name, :description, :maximum, :visible, :order))
          else
            item.destroy
          end
        end
        new_items.each do |item|
          @evaluation_exercise.score_items.create!(item.permit(:name, :description, :maximum, :visible, :order))
        end
      rescue ActiveRecord::RecordInvalid => e
        return render json: { errors: e.record.errors }, status: :unprocessable_entity
      end
    end

    respond_to do |format|
      @evaluation.reload
      format.js { render 'score_items/index', locals: { new: nil, evaluation_exercise: @evaluation_exercise.reload } }
      format.json { head :no_content }
    end
  end

  private

  def set_evaluation_exercise
    @evaluation_exercise = EvaluationExercise.find(params[:id])
    @evaluation = @evaluation_exercise.evaluation
    authorize @evaluation, :update?
  end
end
