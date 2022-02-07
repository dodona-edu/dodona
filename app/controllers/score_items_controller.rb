class ScoreItemsController < ApplicationController
  include SeriesHelper

  before_action :set_score_item, only: %i[destroy update]
  before_action :set_evaluation

  def copy
    from = EvaluationExercise.find(params[:copy][:from])
    to = EvaluationExercise.find(params[:copy][:to])

    from.score_items.each do |score_item|
      new_score_item = score_item.dup
      new_score_item.evaluation_exercise = to
      new_score_item.last_updated_by = current_user
      new_score_item.save
    end

    # Score items have changed.
    @evaluation.score_items.reload
    respond_to do |format|
      format.js { render 'score_items/index', locals: { new: nil, evaluation_exercise: to } }
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

  def add_all
    @score_item = ScoreItem.new(permitted_attributes(ScoreItem, :create))
    @score_item.last_updated_by = current_user
    # Add all score items or none.
    @evaluation.transaction do
      @evaluation.evaluation_exercises.each do |evaluation_exercise|
        new_score_item = @score_item.dup
        evaluation_exercise.score_items << new_score_item
      end
    end
    @evaluation.reload
  end

  def destroy
    @score_item.destroy
    respond_to do |format|
      format.js { render 'score_items/index', locals: { new: nil, evaluation_exercise: preload_eval_exercise(@score_item) } }
      format.json { render json: {}, status: :no_content }
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
    ActiveRecord::Associations::Preloader.new(records: item.evaluation_exercise, associations: [score_items: :scores])
    item.evaluation_exercise
  end
end
