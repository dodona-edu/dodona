class ScoreItemsController < ApplicationController
  include SeriesHelper

  before_action :set_score_item, only: %i[destroy update]
  before_action :set_evaluation

  def create
    @score_item = ScoreItem.new(permitted_attributes(ScoreItem))
    @score_item.last_updated_by = current_user
    respond_to do |format|
      if @score_item.save
        format.js { render 'score_items/index', locals: { new: nil, evaluation_exercise: preload_eval_exercise(@score_item) } }
        format.json { render :show, status: :created, location: [@evaluation, @score_item] }
      else
        format.js { render 'score_items/index', locals: { new: @score_item, evaluation_exercise: preload_eval_exercise(@score_item) } }
        format.json { render json: @score_item.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    args = permitted_attributes(@score_item)
    args[:last_updated_by] = current_user
    respond_to do |format|
      if @score_item.update(args)
        format.js { render 'score_items/index', locals: { new: nil, evaluation_exercise: preload_eval_exercise(@score_item) } }
        format.json { render :show, status: :ok, location: [@evaluation, @score_item] }
      else
        format.js { render 'score_items/index', locals: { new: @score_item, evaluation_exercise: preload_eval_exercise(@score_item) } }
        format.json { render json: @score_item.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_all
    @evaluation_exercise = EvaluationExercise.find(params[:evaluation_exercise_id])
    Rails.logger.debug { "update_all: #{params[:score_items]}" }
    authorize @evaluation_exercise, :update?

    ScoreItem.transaction do
      new_items = params[:score_items].filter { |item| item[:id].blank? }
      updated_items = params[:score_items].filter { |item| item[:id].present? }
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
    end

    respond_to do |format|
      @evaluation.reload
      format.js { render 'score_items/index', locals: { new: nil, evaluation_exercise: @evaluation_exercise.reload } }
      format.json { head :no_content }
    end
  end

  def destroy
    @score_item.destroy
    respond_to do |format|
      format.js { render 'score_items/index', locals: { new: nil, evaluation_exercise: preload_eval_exercise(@score_item) } }
      format.json { head :no_content }
    end
  end

  private

  def set_score_item
    @score_item = ScoreItem.find(params[:id])
  end

  def set_evaluation
    # Include a bunch of stuff to reduce number of queries on show pages.
    @evaluation = Evaluation.includes(evaluation_exercises: :exercise, score_items: :scores).find(params[:evaluation_id])
    authorize @evaluation, :score_items?

    @crumbs = [
      [@evaluation.series.course.name, course_path(@evaluation.series.course)],
      [@evaluation.series.name, breadcrumb_series_path(@evaluation.series, current_user)],
      [I18n.t('evaluations.show.evaluation'), evaluation_path(@evaluation)]
    ]
  end

  def preload_eval_exercise(item)
    # Reload the evaluation, since one of the items changed.
    @evaluation.score_items.reload
    # Preload the stuff for one exercise and an existing instance.
    EvaluationExercise.includes({ score_items: :scores }).find(item.evaluation_exercise.id)
  end
end
