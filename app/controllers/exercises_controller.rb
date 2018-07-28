class ExercisesController < ApplicationController
  before_action :set_exercise, only: %i[show edit update media]
  before_action :ensure_trailing_slash, only: :show
  skip_before_action :verify_authenticity_token, only: [:media]

  has_scope :by_filter, as: 'filter'

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to exercises_path, alert: I18n.t('exercises.show.not_found')
  end

  def index
    authorize Exercise
    @exercises = policy_scope(Exercise).merge(apply_scopes(Exercise).all).order('name_' + I18n.locale.to_s).paginate(page: params[:page])

    if params[:repository_id]
      @repository = Repository.find(params[:repository_id])
      @exercises = @exercises.in_repository(@repository)
    end
    @series = Series.find(params[:series_id]) if params[:series_id]
    @title = I18n.t('exercises.index.title')
  end

  def show
    flash.now[:notice] = I18n.t('exercises.show.not_accessible') if @exercise.closed?
    flash.now[:notice] = I18n.t('exercises.show.not_visible') if @exercise.hidden? && policy(@exercise).edit?
    @course = Course.find_by(id: params[:course_id])
    flash.now[:alert] = I18n.t('exercises.show.not_a_member') if @course && !current_user&.member_of?(@course)
    @series = Series.by_course_and_exercise(@course, @exercise).first
    @submissions = @exercise.submissions
    @submissions = @submissions.in_course(@course) unless @course.nil?
    @submissions = policy_scope(@submissions).paginate(page: params[:page])
    if params[:edit_submission]
      @edit_submission = Submission.find(params[:edit_submission])
      authorize @edit_submission, :edit?
    end
    @title = @exercise.name
    @crumbs = [[@course.name, course_path(@course)], [@exercise.name, "#"]] unless @course.nil?
  end

  def edit
    @title = @exercise.name
    @crumbs = [[@exercise.name, exercise_path(@exercise)], [I18n.t('crumbs.edit'), "#"]]
  end

  def update
    respond_to do |format|
      if @exercise.update(permitted_attributes(@exercise))
        format.html { redirect_to exercise_path(@exercise), flash: { success: I18n.t('controllers.updated', model: Exercise.model_name.human) } }
        format.json { render :show, status: :ok, location: @exercise }
      else
        format.html { render :edit }
        format.json { render json: @exercise.errors, status: :unprocessable_entity }
      end
    end
  end

  def media
    file = File.join(@exercise.media_path, params[:media])
    unless File.file? file
      file = File.join(@exercise.repository.media_path, params[:media])
    end
    raise ActionController::RoutingError, 'Not Found' unless File.file? file
    send_file file, disposition: 'inline'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_exercise
    @exercise = Exercise.find(params[:id])
    authorize @exercise
  end
end
