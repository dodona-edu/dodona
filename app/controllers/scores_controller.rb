class ScoresController < ApplicationController
  before_action :set_score, only: %i[update destroy]
  before_action :set_evaluation

  def create
    @score = Score.new(permitted_attributes(Score))
    @score.last_updated_by = current_user
    authorize @score
    respond_to do |format|
      if @score.save
        set_common
        format.js { render :show }
        format.json { render :show, status: :created, location: [@evaluation, @score] }
      else
        format.json { render json: @score.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @score.update(permitted_attributes(Score))
        set_common
        format.js { render :show }
        format.json { render :show, status: :created, location: [@evaluation, @score] }
      else
        format.json { render json: @score.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @score.destroy
    set_common
    respond_to do |format|
      format.js { render 'feedbacks/show' }
      format.json { render json: {}, status: :no_content }
    end
  end

  private

  def set_evaluation
    @evaluation = Evaluation.find(params[:evaluation_id])
    authorize @evaluation, :manage_scores?
  end

  def set_score
    @score = Score.find(params[:id])
    @score.attributes = { expected_score: params[:score]&.[](:expected_score) }
    authorize @score
  end

  def set_common
    @feedback = @score.feedback
    @score_map = @feedback.scores.index_by(&:rubric_id)
    @order = @score.feedback.evaluation_exercise.rubrics.order(:id).find_index { |r| r.id == @score.rubric_id }
    @total = @score.feedback.score
  end
end
