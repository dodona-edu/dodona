class ExercisesController < ApplicationController
  before_action :set_exercise, only: %i[show edit update media]
  before_action :set_course, only: %i[show edit update]
  before_action :set_series, only: %i[show edit update]
  before_action :ensure_trailing_slash, only: :show
  skip_before_action :verify_authenticity_token, only: [:media]

  has_scope :by_filter, as: 'filter'
  has_scope :by_labels, as: 'labels', type: :array, if: ->(this) {this.params[:labels].is_a?(Array)}
  has_scope :by_programming_language, as: 'programming_language'
  has_scope :in_repository, as: 'repository_id'

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

    @exercises = @exercises.order('name_' + I18n.locale.to_s).order(path: :asc).paginate(page: parse_pagination_param(params[:page]))
    @labels = policy_scope(Label.all)
    @programming_languages = policy_scope(ProgrammingLanguage.all)
    @repositories = policy_scope(Repository.all)
    @title = I18n.t('exercises.index.title')
  end

  def available
    @series = Series.find(params[:id])
    @course = @series.course
    authorize @series, :edit?
    @exercises = policy_scope(Exercise)
    @exercises = @exercises.or(Exercise.where(repository: @course.usable_repositories))
    @exercises = apply_scopes(@exercises)
    @exercises = @exercises.order('name_' + I18n.locale.to_s).order(path: :asc).paginate(page: parse_pagination_param(params[:page]))
  end

  def show
    flash.now[:alert] = I18n.t('exercises.show.not_a_member') if @course && !current_user&.member_of?(@course)
    # We still need to check access because an unauthenticated user should be able to see public exercises
    unless @exercise.accessible?(current_user, @course)
      raise Pundit::NotAuthorizedError, "Not allowed"
    end

    @series = Series.find_by(id: params[:series_id])
    flash.now[:alert] = I18n.t('exercises.show.not_a_member') if @course && !current_user&.member_of?(@course)
    @submissions = @exercise.submissions
    if @course.present? && current_user&.member_of?(@course)
      @submissions = @submissions.in_course(@course)
    end
    @submissions = @submissions.of_user(current_user) if current_user
    @submissions = policy_scope(@submissions).paginate(page: parse_pagination_param(params[:page]))
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
    attributes = permitted_attributes(@exercise)

    labels = params[:exercise][:labels]
    if labels
      unless labels.is_a?(Array)
        labels = labels&.split(',')
      end
      labels = (labels + (@exercise.merged_dirconfig[:labels] || []))
      attributes[:labels] = labels&.map(&:downcase).uniq.map {|name| Label.find_by(name: name) || Label.create(name: name)}
    end

    respond_to do |format|
      if @exercise.update(attributes)
        format.html {redirect_to helpers.exercise_scoped_path(exercise: @exercise, course: @course, series: @series), flash: {success: I18n.t('controllers.updated', model: Exercise.model_name.human)}}
        format.json {render :show, status: :ok, location: @exercise}
      else
        format.html {render :edit}
        format.json {render json: @exercise.errors, status: :unprocessable_entity}
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
    if @series.hidden?
      @crumbs << [@series.name, series_path(@series)]
    else
      @crumbs << [@series.name, course_path(@series.course, anchor: @series.anchor)]
    end
    authorize @series
  end
end
