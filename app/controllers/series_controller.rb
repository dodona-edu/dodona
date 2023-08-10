class SeriesController < ApplicationController
  include ExportHelper
  include SetLtiMessage

  before_action :set_series, except: %i[index new create]
  before_action :check_token, only: %i[show overview]
  before_action :set_lti_message, only: %i[show]
  before_action :set_lti_provider, only: %i[show]

  has_scope :at_least_one_started, type: :boolean, only: :scoresheet do |controller, scope|
    scope.at_least_one_started_in_series(Series.find(controller.params[:id])).or(scope.at_least_one_read_in_series(Series.find(controller.params[:id])))
  end
  has_scope :by_course_labels, as: 'course_labels', type: :array, only: :scoresheet do |controller, scope, value|
    scope.by_course_labels(value, Series.find(controller.params[:id]).course_id)
  end
  has_scope :by_filter, as: 'filter', only: :scoresheet

  has_scope :order_by, using: %i[column direction], only: :scoresheet, type: :hash do |controller, scope, value|
    column, direction = value
    if %w[ASC DESC].include?(direction)
      case column
      when 'status_in_course_and_name'
        scope.order_by_status_in_course_and_name direction
      when 'submission_statuses_in_series'
        series = Series.find(controller.params[:id])
        scope.order_by_submission_statuses_in_series direction, series
      else
        series = Series.find(controller.params[:id])
        if series.activities.exists? id: column
          activity = series.activities.find(column)
          if activity.exercise?
            scope.order_by_exercise_submission_status_in_series direction, activity, series
          elsif activity.content_page?
            scope.order_by_activity_read_state_in_series direction, activity, series
          else
            scope
          end
        else
          scope
        end
      end
    else
      scope
    end
  end

  content_security_policy only: %i[overview] do |policy|
    policy.frame_src -> { sandbox_url }
  end

  # GET /series
  # GET /series.json
  def index
    authorize Series
    @course = Course.find(params[:course_id])
    @series = policy_scope(@course.series)
    @title = I18n.t('series.index.title')
  end

  # GET /series/1
  # GET /series/1.json
  def show
    @course = @series.course
    @current_membership = CourseMembership.where(course: @course, user: current_user).first
    @title = @series.name
    @crumbs = [[@course.name, course_path(@course)], [@series.name, '#']]
    @user = User.find(params[:user_id]) if params[:user_id] && current_user&.course_admin?(@course)
    flash.now[:alert] = I18n.t('series.show.hidden_not_registered') if @series.hidden? && !current_user&.subscribed_courses&.include?(@course)
  end

  def overview
    @title = "#{@series.course.name} #{@series.name}"
    @course = @series.course
    @crumbs = [[@course.name, course_path(@course)], [@series.name, course_path(@series.course, anchor: @series.anchor)], [I18n.t('crumbs.overview'), '#']]
    @user = User.find(params[:user_id]) if params[:user_id] && current_user&.course_admin?(@course)
  end

  # GET /series/new
  def new
    course = Course.find(params[:course_id])
    authorize course, :add_series?
    @series = Series.new(course: course)
    @title = I18n.t('series.new.title')
    @crumbs = [[course.name, course_path(course)], [I18n.t('series.new.title'), '#']]
  end

  # GET /series/1/edit
  def edit
    @title = @series.name
    @crumbs = [[@series.course.name, course_path(@series.course)], [@series.name, course_path(@series.course, anchor: @series.anchor)], [I18n.t('crumbs.edit'), '#']]
    @labels = policy_scope(Label.all)
    @programming_languages = policy_scope(ProgrammingLanguage.all)
    @repositories = policy_scope(Repository.all)

    @tabs = []
    @tabs << { id: :mine, name: I18n.t('activities.index.tabs.mine'), title: I18n.t('activities.index.tabs.mine_course_title') }
    if current_user.institution.present?
      @tabs << { id: :my_institution,
                 name: I18n.t('activities.index.tabs.my_institution', institution: current_user.institution.short_name || current_user.institution.name),
                 title: I18n.t('activities.index.tabs.my_institution_title') }
    end
    @tabs << { id: :featured, name: I18n.t('activities.index.tabs.featured'), title: I18n.t('activities.index.tabs.featured_title') }
    @tabs << { id: :all, name: I18n.t('activities.index.tabs.all'), title: I18n.t('activities.index.tabs.all_title') }
    @tabs = @tabs.filter { |t| Activity.repository_scope(scope: t[:id], user: current_user, course: @series.course).any? }
  end

  # POST /series
  # POST /series.json
  def create
    @series = Series.new(permitted_attributes(Series))
    authorize @series
    respond_to do |format|
      if @series.save
        format.html { redirect_to edit_series_path(@series), notice: I18n.t('controllers.created', model: Series.model_name.human) }
        format.json { render :show, status: :created, location: @series }
      else
        format.html { render :new }
        format.json { render json: @series.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /series/1
  # PATCH/PUT /series/1.json
  def update
    respond_to do |format|
      if @series.update(permitted_attributes(@series))
        format.html { redirect_to course_path(@series.course, series: @series, anchor: @series.anchor), notice: I18n.t('controllers.updated', model: Series.model_name.human) }
        format.json { render :show, status: :ok, location: @series }
      else
        format.html { render :edit }
        format.json { render json: @series.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /series/1
  # DELETE /series/1.json
  def destroy
    @series.destroy
    respond_to do |format|
      format.html { redirect_to request.referer || course_path(@series.course), notice: I18n.t('controllers.destroyed', model: Series.model_name.human) }
      format.json { head :no_content }
    end
  end

  def reset_token
    type = params[:type].to_sym
    value =
      case type
      when :access_token
        @series.generate_access_token
        series_url(@series, token: @series.access_token)
      else
        # unknown token type
        head :unacceptable
      end

    return if performed?

    @series.save
    render partial: 'application/token_field', locals: {
      container_name: :access_token_field,
      name: type,
      value: value,
      reset_url: reset_token_series_path(@series, type: type)
    }
  end

  def add_activity
    @activity = Activity.find(params[:activity_id])
    unless @activity.usable_by? @series.course
      if current_user.repository_admin? @activity.repository
        @series.course.usable_repositories << @activity.repository
      else
        render status: :forbidden
        return
      end
    end
    SeriesMembership.create(series: @series, activity: @activity)
  end

  def remove_activity
    @activity = Activity.find(params[:activity_id])
    @series.activities.destroy(@activity)
  end

  def reorder_activities
    order = JSON.parse(params[:order])
    @series.series_memberships.each do |membership|
      rank = order.find_index(membership.activity_id) || 0
      membership.update(order: rank)
    end
  end

  def scoresheet
    @course = @series.course
    @title = @series.name
    @course_labels = CourseLabel.where(course: @course)

    scores = @series.scoresheet
    @users = apply_scopes(scores[:users])
    @activities = scores[:activities]
    @submissions = scores[:submissions]
    @read_states = scores[:read_states]
    @statuses = Submission.statuses.keys

    @submission_counts = Hash.new(0)
    @read_state_counts = Hash.new(0)
    @summary_by_user = Hash.new(0)
    @total = Hash.new(0)
    @users.each do |user|
      @activities.each do |activity|
        if activity.exercise? && @submissions[[user.id, activity.id]].present?
          @submission_counts[[activity.id, @submissions[[user.id, activity.id]].status]] += 1
          @summary_by_user[[user.id, @submissions[[user.id, activity.id]].status]] += 1
          @total[@submissions[[user.id, activity.id]].status] += 1
        elsif activity.content_page? && @read_states[[user.id, activity.id]].present?
          @read_state_counts[activity.id] += 1
          @summary_by_user[[user.id, 'correct']] += 1
          @total['correct'] += 1
        end
      end
    end

    @crumbs = [[@course.name, course_path(@course)], [@series.name, course_path(@series.course, anchor: @series.anchor)], [I18n.t('crumbs.overview'), '#']]

    respond_to do |format|
      format.html
      format.js
      format.json
      format.csv do
        users_labels = @course.course_memberships
                              .includes(:course_labels, :user)
                              .to_h { |m| [m.user, m.course_labels] }

        sheet = CSV.generate(force_quotes: true) do |csv|
          columns = ['id', 'username', 'last_name', 'first_name', 'email', 'labels', @series.name]
          columns.concat(@activities.map(&:name))
          columns.concat(@activities.map { |a| I18n.t('series.scoresheet.status', activity: a.name) })
          csv << columns
          csv << ['Maximum', '', '', '', '', '', @activities.count].concat(@activities.map { 1 }).concat(@activities.map { '' })
          @users.each do |u|
            row = [u.id, u.username, u.first_name, u.last_name, u.email, users_labels[u].map(&:name).join(';')]
            succeeded_exercises = @activities.map do |a|
              if a.exercise?
                @submissions[[u.id, a.id]]&.accepted ? 1 : 0
              elsif a.content_page?
                @read_states[[u.id, a.id]].present? ? 1 : 0
              end
            end
            exercise_status = @activities.map do |a|
              if a.exercise?
                @submissions[[u.id, a.id]]&.status || 'unstarted'
              elsif a.content_page?
                @read_states[[u.id, a.id]].present? ? 'read' : 'unread'
              end
            end
            row << succeeded_exercises.sum
            row.concat(succeeded_exercises)
            row.concat(exercise_status)
            csv << row
          end
        end
        filename = "scoresheet-#{@series.name.parameterize}.csv"
        send_data(sheet, type: 'text/csv', filename: filename, disposition: 'attachment', x_sendfile: true)
      end
    end
  end

  def mass_rejudge
    @submissions = Submission.in_series(@series)
    Event.create(event_type: :rejudge, user: current_user, message: "#{@submissions.count} submissions")
    Submission.rejudge_delayed(@submissions)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_series
    @series = Series.find(params[:id])
    authorize @series
  end

  def check_token
    raise Pundit::NotAuthorizedError if @series.hidden? &&
                                        !current_user&.course_admin?(@series.course) &&
                                        @series.access_token != params[:token]
  end

  def send_zip(zip)
    send_data zip[:data],
              type: 'application/zip',
              filename: zip[:filename],
              disposition: 'attachment',
              x_sendfile: true
  end
end
