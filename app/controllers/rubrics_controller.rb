class RubricsController < ApplicationController
  include RescueJsonResponse

  before_action :set_rubric, only: %i[destroy update]
  before_action :set_evaluation

  def copy
    from = EvaluationExercise.find(params[:copy][:from])
    to = EvaluationExercise.find(params[:copy][:to])

    from.rubrics.each do |rubric|
      new_rubric = rubric.dup
      new_rubric.evaluation_exercise = to
      new_rubric.last_updated_by = current_user
      new_rubric.save!
    end

    respond_to do |format|
      format.js { render 'rubrics/refresh', locals: { new: nil, evaluation_exercise: to } }
    end
  end

  def update
    args = permitted_attributes(@rubric)
    args[:last_updated_by] = current_user
    @rubric.update!(permitted_attributes(@rubric))
    respond_to do |format|
      format.js { render 'rubrics/refresh', locals: { new: nil, evaluation_exercise: @rubric.evaluation_exercise } }
      format.json { render :show, status: :ok, location: [@evaluation, @rubric] }
    end
  end

  def create
    @rubric = Rubric.new(permitted_attributes(Rubric))
    authorize @rubric
    @rubric.last_updated_by = current_user
    @rubric.save!
    respond_to do |format|
      format.js { render 'rubrics/refresh', locals: { new: nil, evaluation_exercise: @rubric.evaluation_exercise } }
      format.json { render :show, status: :created, location: [@evaluation, @rubric] }
    end
  end

  def destroy
    @rubric.destroy!
    respond_to do |format|
      format.js { render 'rubrics/refresh', locals: { new: nil, evaluation_exercise: @rubric.evaluation_exercise } }
      format.json { render json: {}, status: :no_content }
    end
  end

  private

  def set_rubric
    @rubric = Rubric.find(params[:id])
    authorize @rubric
  end

  def set_evaluation
    @evaluation = Evaluation.find(params[:evaluation_id])
    authorize @evaluation, :rubrics?

    @crumbs = [
      [@evaluation.series.course.name, course_path(@evaluation.series.course)],
      [@evaluation.series.name, series_path(@evaluation.series)],
      [I18n.t('evaluations.show.evaluation'), evaluation_path(@evaluation)]
    ]
  end
end
