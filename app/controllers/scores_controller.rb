class ScoresController < ApplicationController
  include RescueJsonResponse

  before_action :set_score, only: %i[update destroy]
  before_action :set_evaluation

  def create
    @score = Score.new(permitted_attributes(Score))
    @score.last_updated_by = current_user
    authorize @score
    @score.save!
    set_feedback_and_score_map
    respond_to do |format|
      format.js { render 'feedbacks/update' }
      format.json { render :show, status: :created, location: [@evaluation, @score] }
    end
  end

  def update
    @score.update!(permitted_attributes(Score))
    set_feedback_and_score_map
    respond_to do |format|
      format.js { render 'feedbacks/update' }
      format.json { render :show, location: [@evaluation, @score] }
    end
  end

  def destroy
    @score.destroy!
    set_feedback_and_score_map
    respond_to do |format|
      format.js { render 'feedbacks/update' }
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

  def set_feedback_and_score_map
    @feedback = @score.feedback
    @score_map = @feedback.scores.index_by(&:rubric_id)
  end
end
