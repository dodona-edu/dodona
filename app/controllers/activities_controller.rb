class ActivitiesController < ApplicationController
  include SeriesHelper

  before_action :set_activity, only: %i[show description edit update media info read]
  before_action :set_course, only: %i[show edit update media info read]
  before_action :set_series, only: %i[show edit update info read]
  before_action :ensure_trailing_slash, only: :show
  before_action :allow_iframe, only: %i[description]
  # Some activity descriptions load JavaScript from their description. Rails has extra protections against loading unprivileged javascript.
  skip_before_action :verify_authenticity_token, only: [:media]
  skip_before_action :redirect_to_default_host, only: %i[description media]

  has_scope :by_filter, as: 'filter'
  has_scope :by_labels, as: 'labels', type: :array, if: ->(this) { this.params[:labels].is_a?(Array) }
  has_scope :by_programming_language, as: 'programming_language'
  has_scope :by_type, as: 'type'
  has_scope :in_repository, as: 'repository_id'

  content_security_policy only: %i[show] do |policy|
    policy.frame_src -> { ["'self'", sandbox_url] }
  end

  content_security_policy only: %i[description] do |policy|
    policy.frame_ancestors -> { default_url }
  end

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to activities_path, alert: I18n.t('activities.show.not_found')
  end

  def index
    authorize Activity

    @activities = if params[:series_id]
                    @series = Series.find(params[:series_id])
                    authorize @series, :show?
                    policy(@series).overview? ? @series.activities : []
                  else
                    policy_scope(Activity)
                  end

    if params[:repository_id]
      @repository = Repository.find(params[:repository_id])
      @activities = @activities.in_repository(@repository)
    end

    @activities = @activities.by_description_language(params[:description_language]) if params[:description_language].present?

    unless @activities.empty?
      @activities = apply_scopes(@activities)
      @activities = @activities.order('name_' + I18n.locale.to_s).order(path: :asc).paginate(page: parse_pagination_param(params[:page]))
    end
    @labels = policy_scope(Label.all)
    @programming_languages = policy_scope(ProgrammingLanguage.all)
    @repositories = policy_scope(Repository.all)
    @title = I18n.t('activities.index.title')
  end

  def available
    @series = Series.find(params[:id])
    @course = @series.course
    authorize @series, :edit?
    @activities = policy_scope(Activity)
    @activities = @activities.or(Activity.where(repository: @course.usable_repositories))
    @activities = apply_scopes(@activities)
    @activities = @activities.order('name_' + I18n.locale.to_s).order(path: :asc).paginate(page: parse_pagination_param(params[:page]))
  end

  def show
    flash.now[:alert] = I18n.t('activities.show.not_a_member') if @course && !current_user&.member_of?(@course)
    # We still need to check access because an unauthenticated user should be able to see public activities
    raise Pundit::NotAuthorizedError, 'Not allowed' unless @activity.accessible?(current_user, @course)

    @series = Series.find_by(id: params[:series_id])
    flash.now[:alert] = I18n.t('activities.show.not_a_member') if @course && !current_user&.member_of?(@course)
    if @activity.exercise?
      @submissions = @activity.submissions.includes(:annotations)
      @submissions = @submissions.in_course(@course) if @course.present? && current_user&.member_of?(@course)
      @submissions = @submissions.of_user(current_user) if current_user
      @submissions = policy_scope(@submissions).paginate(page: parse_pagination_param(params[:page]))
      if params[:edit_submission]
        @edit_submission = Submission.find(params[:edit_submission])
        authorize @edit_submission, :edit?
      end
      if params[:from_solution]
        @solution = @activity.solutions[params[:from_solution]]
        authorize @activity, :info?
      end

      @code = @edit_submission.try(:code) || @solution || @activity.boilerplate
    elsif @activity.content_page?
      @read_state = if current_user&.member_of?(@course)
                      @activity.activity_read_states.find_by(user: current_user, course: @course)
                    else
                      @activity.activity_read_states.find_by(user: current_user)
                    end
    end

    @title = @activity.name
    @crumbs << [@activity.name, '#']
  end

  def description
    raise Pundit::NotAuthorizedError, 'Not allowed' unless @activity.access_token == params[:token]

    render layout: 'frame'
  end

  def info
    @title = @activity.name
    @repository = @activity.repository
    @config = @activity.merged_config
    @config_locations = @activity.merged_config_locations
    @crumbs << [@activity.name, helpers.activity_scoped_path(activity: @activity, series: @series, course: @course)] << [I18n.t('crumbs.info'), '#']
    @courses_series = policy_scope(@activity.series).group_by(&:course).sort do |a, b|
      [b.first.year, a.first.name] <=> [a.first.year, b.first.name]
    end
  end

  def edit
    @title = @activity.name
    @crumbs << [@activity.name, helpers.activity_scoped_path(activity: @activity, series: @series, course: @course)] << [I18n.t('crumbs.edit'), '#']
    @labels = Label.all
  end

  def read
    @course = nil if @course.blank? || !@course.subscribed_members.include?(current_user)
    read_state = ActivityReadState.new activity: @activity,
                                       course: @course,
                                       user: current_user
    if read_state.save
      respond_to do |format|
        format.html { redirect_to helpers.activity_scoped_path(activity: @activity, course: @course, series: @series) }
        format.js { render 'activities/read', locals: { activity: @activity, course: @course, read_state: read_state, user: current_user } }
        format.json { head :ok }
      end
    else
      render json: { status: 'failed', errors: read_state.errors }, status: :unprocessable_entity
    end
  end

  def update
    attributes = permitted_attributes(@activity.becomes(Activity))

    labels = params[:activity][:labels]
    if labels
      labels = labels&.split(',') unless labels.is_a?(Array)
      labels = (labels + (@activity.merged_dirconfig[:labels] || []))
      attributes[:labels] = labels&.map(&:downcase)&.uniq&.map { |name| Label.find_by(name: name) || Label.create(name: name) }
    end

    respond_to do |format|
      if @activity.update(attributes)
        format.html { redirect_to helpers.activity_scoped_path(activity: @activity, course: @course, series: @series), flash: { success: I18n.t('controllers.updated', model: Activity.model_name.human) } }
        format.json { render :show, status: :ok, location: @activity }
      else
        format.html { render :edit }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  def media
    if params.key?(:token)
      raise Pundit::NotAuthorizedError, 'Not allowed' unless @activity.access_token == params[:token]
    elsif !@activity.accessible?(current_user, @course)
      raise Pundit::NotAuthorizedError, 'Not allowed'
    end

    file = File.join(@activity.media_path, params[:media])
    file = File.join(@activity.repository.media_path, params[:media]) unless File.file? file
    raise ActionController::RoutingError, 'Not Found' unless File.file? file

    type = Mime::Type.lookup_by_extension File.extname(file)[1..]
    type = 'text/plain; charset=utf-8' if type.nil? || type == 'text/plain'

    # Support If-Modified-Since caching
    send_file file, disposition: 'inline', type: type \
      if stale? last_modified: File.mtime(file)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_activity
    @activity = Activity.find(params[:id])
    authorize @activity
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
    @crumbs << [@series.name, breadcrumb_series_path(@series, current_user)]
    authorize @series
  end
end
