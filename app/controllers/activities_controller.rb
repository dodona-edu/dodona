class ActivitiesController < ApplicationController
  include SeriesHelper
  include SetLtiMessage
  include Sortable

  INPUT_SERVICE_WORKER = 'inputServiceWorker.js'.freeze

  before_action :set_activity, only: %i[show description edit update media info]
  before_action :set_course, only: %i[show edit update media info]
  before_action :set_series, only: %i[show edit update media info]
  before_action :ensure_trailing_slash, only: :show
  before_action :set_lti_message, only: %i[show]
  before_action :set_lti_provider, only: %i[show]
  skip_before_action :redirect_to_default_host, only: %i[description media]
  # Some activity descriptions load JavaScript from their description. Rails has
  # extra protections against loading unprivileged javascript. We also need to
  # make sure the Papyros service worker can be loaded.
  protect_from_forgery except: %i[media input_service_worker]

  has_scope :by_filter, as: 'filter'
  has_scope :by_labels, as: 'labels', type: :array, if: ->(this) { this.params[:labels].is_a?(Array) }
  has_scope :by_programming_language, as: 'programming_language'
  has_scope :by_type, as: 'type'
  has_scope :in_repository, as: 'repository_id'
  has_scope :by_description_languages, as: 'description_languages', type: :array
  has_scope :by_judge, as: 'judge_id'
  has_scope :by_popularities, as: 'popularity', type: :array
  has_scope :is_draft, as: 'draft'

  has_scope :repository_scope, as: 'tab' do |controller, scope, value|
    course = Series.find(controller.params[:id]).course if controller.params[:id]
    scope.repository_scope(scope: value, user: controller.current_user, course: course)
  end

  order_by :popularity, :name

  content_security_policy only: %i[show] do |policy|
    policy.frame_src -> { ["'self'", sandbox_url] }
    policy.worker_src -> { ['blob:', "'self'"] }
    # Safari doesn't support worker_src and falls back to child_src
    # This should be fixed in Safari 15.5 https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/worker-src#browser_compatibility
    policy.child_src -> { ['blob:', "'self'"] }
    # Allow fetching Pyodide and related packages
    # The data: urls is specifically to allow fetching the Python dependencies via a bundled tar that
    # is extracted into the Pyodide environment at runtime
    policy.script_src(*(%w[https://cdn.jsdelivr.net/pyodide/] + policy.script_src))
    policy.connect_src(*(%w[data: https://cdn.jsdelivr.net/pyodide/ https://pypi.org/pypi/ https://files.pythonhosted.org/packages/] + policy.connect_src))
  end

  content_security_policy only: %i[description] do |policy|
    policy.frame_ancestors -> { allowed_frame_ancestors }
  end

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to activities_path, alert: I18n.t('activities.show.not_found')
  end

  def index
    authorize Activity

    @activities = if params[:series_id]
                    @series = Series.find(params[:series_id])
                    authorize @series, :show?
                    raise Pundit::NotAuthorizedError unless policy(@series).valid_token?(params[:token])

                    policy(@series).overview? ? @series.activities : []
                  else
                    policy_scope(Activity).order_by_popularity(:DESC)
                  end

    if params[:repository_id]
      @repository = Repository.find(params[:repository_id])
      @activities = @activities.in_repository(@repository)
    end

    unless @activities.empty?
      @activities = apply_scopes(@activities)
      @activities = @activities.paginate(page: parse_pagination_param(params[:page]))
    end
    @labels = policy_scope(Label.all)
    @programming_languages = policy_scope(ProgrammingLanguage.all)
    @repositories = policy_scope(Repository.all)
    @judges = policy_scope(Judge.all)
    @title = I18n.t('activities.index.title')

    @tabs = []
    @tabs << { id: :mine, name: I18n.t('activities.index.tabs.mine'), title: I18n.t('activities.index.tabs.mine_title') }
    if current_user&.institution.present?
      @tabs << { id: :my_institution,
                 name: I18n.t('activities.index.tabs.my_institution', institution: current_user.institution.short_name || current_user.institution.name),
                 title: I18n.t('activities.index.tabs.my_institution_title') }
    end
    @tabs << { id: :featured, name: I18n.t('activities.index.tabs.featured'), title: I18n.t('activities.index.tabs.featured_title') }
    @tabs << { id: :all, name: I18n.t('activities.index.tabs.all'), title: I18n.t('activities.index.tabs.all_title') }
    @tabs = @tabs.filter { |t| Activity.repository_scope(scope: t[:id], user: current_user).any? }
  end

  def available
    @series = Series.find(params[:id])
    @course = @series.course
    authorize @series, :edit?
    @activities = policy_scope(Activity)
    @activities = @activities.or(Activity.where(repository: @course.usable_repositories)).order_by_popularity(:DESC)
    @activities = apply_scopes(@activities)
    @activities = @activities.order("name_#{I18n.locale}").order(path: :asc).paginate(page: parse_pagination_param(params[:page]))
  end

  def show
    flash.now[:alert] = I18n.t('activities.show.not_a_member') if @course && !current_user&.member_of?(@course)

    # Double check if activity still exists within this course (And throw a 404 when it does not)
    @course&.activities&.find(@activity.id) if current_user&.course_admin?(@course)

    # We still need to check access because an unauthenticated user should be able to see public activities
    raise Pundit::NotAuthorizedError, 'Not allowed' unless @activity.accessible?(current_user, course: @course, series: @series)

    # Double check if activity still exists within this series, redirect to course activity if it does not
    redirect_to helpers.activity_scoped_path(activity: @activity, course: @course) if @series&.activities&.exclude?(@activity)

    @not_registered = @course && !current_user&.member_of?(@course)
    flash.now[:alert] = I18n.t('activities.show.not_a_member') if @not_registered
    @current_membership = CourseMembership.where(course: @course, user: current_user).first if @lti_launch && @not_registered
    if @activity.exercise?
      @submissions = @activity.submissions.includes(:annotations)
      @submissions = @submissions.in_course(@course) if @course.present? && current_user&.member_of?(@course)
      @submissions = @submissions.of_user(current_user) if current_user
      @submissions = policy_scope(@submissions)
      if params[:edit_submission]
        @edit_submission = Submission.find(params[:edit_submission])
        authorize @edit_submission, :edit?
      elsif @submissions.any?
        @last_submission = @submissions.first
      end
      @submissions = @submissions.paginate(page: parse_pagination_param(params[:page]))
      if params[:from_solution]
        @solution = @activity.solutions[params[:from_solution]]
        authorize @activity, :info?
      end

      @code = @edit_submission.try(:code) || @solution || @last_submission.try(:code) || @activity.boilerplate
    elsif @activity.content_page?
      @read_state = if current_user&.member_of?(@course)
                      @activity.activity_read_states.find_by(user: current_user, course: @course)
                    else
                      @activity.activity_read_states.find_by(user: current_user, course: nil)
                    end
    end

    @title = @activity.name
    @crumbs << [@activity.name, '#']
  end

  def description
    respond_to :html
    raise Pundit::NotAuthorizedError, 'Not allowed' unless @activity.access_token == params[:token]

    render layout: 'frame'
  end

  def info
    @title = @activity.name
    @repository = @activity.repository
    @config = @activity.ok? ? @activity.merged_config : {}
    @config_locations = @activity.ok? ? @activity.merged_config_locations : {}
    @crumbs << [@activity.name, helpers.activity_scoped_path(activity: @activity, series: @series, course: @course)] << [I18n.t('crumbs.info'), '#']
    @courses_series = policy_scope(@activity.series).group_by(&:course).sort do |a, b|
      [b.first.year, a.first.name] <=> [a.first.year, b.first.name]
    end
    flash.now[:alert] = I18n.t('activities.info.activity_invalid') if @activity.not_valid?
  end

  def edit
    @title = @activity.name
    @crumbs << [@activity.name, helpers.activity_scoped_path(activity: @activity, series: @series, course: @course)] << [I18n.t('crumbs.edit'), '#']
    @labels = Label.all
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
    elsif !@activity.accessible?(current_user, course: @course, series: @series)
      raise Pundit::NotAuthorizedError, 'Not allowed'
    end

    file = File.join(@activity.media_path, params[:media])
    file = File.join(@activity.repository.media_path, params[:media]) unless File.file? file
    raise ActionController::RoutingError, 'Not Found' unless File.file? file

    type = Mime::Type.lookup_by_extension File.extname(file)[1..]
    type = 'text/plain; charset=utf-8' if type.nil? || type == 'text/plain'

    Rack::Files.new(nil).serving(request, file).tap do |(status, headers, body)|
      self.status = status
      self.response_body = body

      headers.each do |name, value|
        response.headers[name] = value
      end
      response.headers['accept-ranges'] = 'bytes'
      response.content_type = type
    end
  end

  # Serve the inputServiceWorker asset required to handle input in Papyros
  # Asset has been preprocessed and built internally
  # Redirecting to the asset is not possible due to browser security policy
  def input_service_worker
    # Which assets are available depends on the mode of the environment
    # The else-block is only reachable in production
    # :nocov:
    filename = if Rails.application.assets
                 Rails.application.assets[INPUT_SERVICE_WORKER].filename
               else
                 File.join(
                   Rails.application.assets_manifest.directory,
                   Rails.application.assets_manifest.assets[INPUT_SERVICE_WORKER]
                 )
               end
    headers['Service-Worker-Allowed'] = '/'
    # :nocov:
    send_file(filename,
              filename: INPUT_SERVICE_WORKER,
              type: 'text/javascript')
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

  def allowed_frame_ancestors
    Rails.configuration.web_hosts.map do |web_host|
      "#{request.protocol}#{web_host}:#{request.port}"
    end
  end
end
