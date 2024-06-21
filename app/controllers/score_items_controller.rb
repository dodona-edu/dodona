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

  def upload
    return render json: { message: I18n.t('course_members.upload_labels_csv.no_file') }, status: :unprocessable_entity if params[:upload].nil? || params[:upload][:file] == 'undefined' || params[:upload][:file].nil?

    file = params[:upload][:file]

    @evaluation_exercise = EvaluationExercise.find(params[:evaluation_exercise_id])
    authorize @evaluation_exercise, :update?

    begin
      headers = CSV.foreach(file.path).first
      %w[name maximum].each do |column|
        return render json: { message: I18n.t('course_members.upload_labels_csv.missing_column', column: column) }, status: :unprocessable_entity unless headers&.include?(column)
      end

      # Remove existing score items.
      @evaluation_exercise.score_items.destroy_all

      CSV.foreach(file.path, headers: true) do |row|
        row = row.to_hash
        score_item = ScoreItem.new(
          name: row['name'],
          maximum: row['maximum'],
          visible: row.key?('visible') ? row['visible'] : true,
          description: row.key?('description') ? row['description'] : nil,
          evaluation_exercise: @evaluation_exercise
        )
        score_item.save!
      end
    rescue CSV::MalformedCSVError
      return render json: { message: I18n.t('course_members.upload_labels_csv.malformed') }, status: :unprocessable_entity
    end


    respond_to do |format|
      format.js { render 'score_items/index', locals: { new: nil, evaluation_exercise: @evaluation_exercise.reload } }
      format.json { head :no_content }
    end
  end

  def index
    @evaluation_exercise = EvaluationExercise.find(params[:evaluation_exercise_id])
    authorize @evaluation_exercise, :show?

    @score_items = policy_scope(@evaluation_exercise.score_items)
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
