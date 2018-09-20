class ExercisesController < ApplicationController
  before_action :set_exercise, only: %i[show edit update media]
  before_action :set_course, only: %i[show edit update]
  before_action :set_series, only: %i[show edit update]
  before_action :ensure_trailing_slash, only: :show
  skip_before_action :verify_authenticity_token, only: [:media]

  has_scope :by_filter, as: 'filter'
  has_scope :by_labels, as: 'labels', type: :array

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to exercises_path, alert: I18n.t('exercises.show.not_found')
  end

  def index
    authorize Exercise

    @exercises = if params[:series_id]
                   @series = Series.find(params[:series_id])
                   authorize @series, :show?
                   @series.exercises
                 else
                   policy_scope(Exercise)
                 end

    if params[:repository_id]
      @repository = Repository.find(params[:repository_id])
      @exercises = @exercises.in_repository(@repository)
    end

    @exercises = apply_scopes(@exercises)

    @exercises = @exercises.order('name_' + I18n.locale.to_s).paginate(page: params[:page])
    @labels = Label.all
    @title = I18n.t('exercises.index.title')
  end

  def available
    @series = Series.find(params[:id])
    @course = @series.course
    authorize @series, :edit?
    @exercises = policy_scope(Exercise)
    @exercises = @exercises.or(Exercise.where(repository: @course.usable_repositories))
    @exercises = @exercises.where.not(id: @series.exercises.map(&:id)) # exclude exercises currently within series
    @exercises = apply_scopes(@exercises)
    @exercises = @exercises.order('name_' + I18n.locale.to_s).paginate(page: params[:page])
    @labels = Label.all
  end

  def show
    flash.now[:alert] = I18n.t('exercises.show.not_a_member') if @course && !current_user&.member_of?(@course)
    # We still need to check access because an unauthenticated user should be able to see public exercises
    if @exercise.access_private? && !current_user&.can_access?(@course, @exercise)
      raise Pundit::NotAuthorizedError, "Not allowed"
    end

    @series = Series.find_by(id: params[:series_id])
    flash.now[:alert] = I18n.t('exercises.show.not_a_member') if @course && !current_user&.member_of?(@course)
    @submissions = @exercise.submissions
    @submissions = @submissions.in_course(@course) unless @course.nil?
    @submissions = @submissions.of_user(current_user) if current_user
    @submissions = policy_scope(@submissions).paginate(page: params[:page])
    if params[:edit_submission]
      @edit_submission = Submission.find(params[:edit_submission])
      authorize @edit_submission, :edit?
    end
    @title = @exercise.name
    @crumbs << [@exercise.name, '#']
  end

  def edit
    @title = @exercise.name
    @crumbs << [@exercise.name, helpers.exercise_scoped_path(exercise: @exercise, series: @series, course: @course)] << [I18n.t('crumbs.edit'), '#']
    @labels = Label.all
  end

  def update
    respond_to do |format|
      if @exercise.update(permitted_attributes(@exercise))
        @exercise.labels = params[:exercise][:labels]&.split(',')&.map { |name| Label.find_by(name: name) || Label.create(name: name) }&.uniq || []
        format.html { redirect_to helpers.exercise_scoped_path(exercise: @exercise, course: @course, series: @series), flash: { success: I18n.t('controllers.updated', model: Exercise.model_name.human) } }
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

  def set_course
    @crumbs = []
    return if params[:course_id].nil?
    @course = Course.find(params[:course_id])
    @crumbs << [@course.name, course_path(@course)]
    authorize @course
  end

  def set_series
    return if params[:series_id].nil?
    @series = Series.find(params[:series_id])
    @crumbs << [@series.name, course_path(@course, series: @series, anchor: "series-#{@series.name.parameterize}")]
    authorize @series
  end
end
