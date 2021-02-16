class RubricsController < ApplicationController
  include RescueJsonResponse

  before_action :set_rubric, only: %i[destroy update]
  before_action :set_evaluation

  def index
    @crumbs << [I18n.t('rubrics.index.title'), '#']
    @title = I18n.t('rubrics.index.title')
  end

  def new
    @crumbs << [I18n.t('rubrics.new.title'), '#']
    @title = I18n.t('rubrics.new.title')
  end

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
    @rubric.update!(args)
    respond_to do |format|
      format.js { render 'rubrics/refresh', locals: { new: nil, evaluation_exercise: @rubric.evaluation_exercise } }
      format.json { render :show, status: :ok, location: [@evaluation, @rubric] }
    end
  end

  def create
    @rubric = Rubric.new(permitted_attributes(Rubric))
    @rubric.last_updated_by = current_user
    @rubric.save!
    respond_to do |format|
      format.js { render 'rubrics/refresh', locals: { new: nil, evaluation_exercise: @rubric.evaluation_exercise } }
      format.json { render :show, status: :created, location: [@evaluation, @rubric] }
    end
  end

  def add_all
    @rubric = Rubric.new(permitted_attributes(Rubric, :create))
    @rubric.last_updated_by = current_user
    # Add all rubrics or none.
    @evaluation.transaction do
      @evaluation.evaluation_exercises.each do |evaluation_exercise|
        new_rubric = @rubric.dup
        new_rubric.evaluation_exercise = evaluation_exercise
        new_rubric.save!
      end
    end

    redirect_to new_evaluation_rubric_path(@evaluation)
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
