class CoursesController < ApplicationController
  include SetLtiMessage

  before_action :set_course_and_current_membership, except: %i[index new create]
  before_action :set_lti_message, only: %i[show]
  before_action :set_lti_provider, only: %i[show]

  has_scope :by_filter, as: 'filter'
  has_scope :by_institution, as: 'institution_id'
  has_scope :at_least_one_started, type: :boolean, only: :scoresheet do |controller, scope|
    scope.at_least_one_started_in_course(Course.find(controller.params[:id]))
  end
  has_scope :by_course_labels, as: 'course_labels', type: :array, only: :scoresheet do |controller, scope, value|
    scope.by_course_labels(value, Series.find(controller.params[:id]).course_id)
  end

  # GET /courses
  # GET /courses.json
  def index
    authorize Course
    @courses = policy_scope(Course.all)
    @show_my_courses = current_user && current_user.subscribed_courses.count > 0
    @show_institution_courses = current_user&.institution && @courses.where(institution: current_user.institution).count > 0

    if current_user && params[:tab] == 'institution'
      @courses = @courses.where(institution: current_user.institution)
    elsif current_user && params[:tab] == 'my'
      @courses = current_user.subscribed_courses
    elsif params[:tab] == 'featured'
      @courses = @courses.where(featured: true)
    elsif params[:copy_courses]
      @courses = @courses.reorder(featured: :desc, year: :desc, name: :asc)
    end

    @courses = apply_scopes(@courses)
    @courses = @courses.paginate(page: parse_pagination_param(params[:page]))
    @repository = Repository.find(params[:repository_id]) if params[:repository_id]
    @institution = Institution.find(params[:institution_id]) if params[:institution_id]
    @copy_courses = params[:copy_courses]
    @title = I18n.t('courses.index.title')
  end

  # GET /courses/1
  # GET /courses/1.json
  def show
    if @course.secret_required?(current_user)
      redirect_unless_secret_correct
      return if performed?
    end
    @title = @course.name
    @series = policy_scope(@course.series).includes(:evaluation)
    @series_loaded = params[:secret].present? ? @course.series.count : 2
  end

  # GET /courses/new
  def new
    authorize Course
    if params[:copy_options]&.fetch(:base_id).present?
      @copy_options = copy_options
      @copy_options[:base] = Course.find(@copy_options[:base_id])
      authorize @copy_options[:base], :copy?
      @course = Course.new(
        name: @copy_options[:base].name,
        description: @copy_options[:base].description,
        institution: current_user.institution,
        visibility: @copy_options[:base].visibility,
        registration: @copy_options[:base].registration,
        teacher: current_user.full_name
      )
      @copy_options = {
        admins: current_user.course_admin?(@copy_options[:base]),
        hide_series: false,
        exercises: true,
        deadlines: false
      }.merge(@copy_options).symbolize_keys
    else
      @copy_options = nil
      @course = Course.new(
        teacher: current_user.full_name,
        institution: current_user.institution
      )
    end

    @title = I18n.t('courses.new.title')
    @crumbs = [[I18n.t('courses.index.title'), courses_path], [I18n.t('courses.new.title'), '#']]
  end

  # GET /courses/1/edit
  def edit
    @title = @course.name
    @crumbs = [[@course.name, course_path(@course)], [I18n.t('crumbs.edit'), '#']]
  end

  # POST /courses
  # POST /courses.json
  def create
    authorize Course
    @course = Course.new(permitted_attributes(Course))

    if params.key? :copy_options
      @copy_options = copy_options.to_h
      @copy_options[:base] = Course.find(@copy_options[:base_id])
      authorize @copy_options[:base], :copy?

      @copy_options = {
        admins: false,
        hide_series: false,
        exercises: false,
        deadlines: false
      }.merge(@copy_options).symbolize_keys

      @course.series = policy_scope(@copy_options[:base].series).map do |s|
        # rubocop:disable Style/MultilineTernaryOperator
        Series.new(
          series_memberships: @copy_options[:exercises] ?
                                  s.series_memberships.map do |sm|
                                    SeriesMembership.new(activity: sm.activity, order: sm.order)
                                  end :
                                  [],
          name: s.name,
          description: s.description,
          visibility: @copy_options[:hide_series] ? :hidden : s.visibility,
          deadline: @copy_options[:deadlines] ? s.deadline : nil,
          order: s.order,
          progress_enabled: s.progress_enabled
        )
        # rubocop:enable Style/MultilineTernaryOperator
      end

      @course.administrating_members = @copy_options[:base].administrating_members if @copy_options[:admins]
    end

    respond_to do |format|
      if @course.save
        flash[:alert] = I18n.t('courses.create.added_private_exercises') unless @course.exercises.where(access: :private).count.zero?
        @course.administrating_members << current_user unless @course.administrating_members.include?(current_user)
        format.html { redirect_to @course, notice: I18n.t('controllers.created', model: Course.model_name.human) }
        format.json { render :show, status: :created, location: @course }
      else
        format.html { render :new }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /courses/1
  # PATCH/PUT /courses/1.json
  def update
    respond_to do |format|
      if @course.update(permitted_attributes(@course))
        format.html { redirect_to @course, notice: I18n.t('controllers.updated', model: Course.model_name.human) }
        format.json { render :show, status: :ok, location: @course }
        format.js { render :reload_questions }
      else
        format.html { render :edit }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /courses/1
  # DELETE /courses/1.json
  def destroy
    @course.destroy
    respond_to do |format|
      format.html { redirect_to courses_url, notice: I18n.t('controllers.destroyed', model: Course.model_name.human) }
      format.json { head :no_content }
    end
  end

  def statistics
    @title = I18n.t('courses.statistics.statistics')
    @crumbs = [[@course.name, course_path(@course)], [I18n.t('courses.statistics.statistics'), '#']]
  end

  def scoresheet
    @title = I18n.t('courses.scoresheet.scoresheet')
    @crumbs = [[@course.name, course_path(@course)], [I18n.t('courses.scoresheet.scoresheet'), '#']]
    @course_labels = CourseLabel.where(course: @course)

    unless request.format == :html
      scores = @course.scoresheet
      @users = apply_scopes(scores[:users])
      @series = scores[:series]
      @hash = scores[:hash]
    end

    respond_to do |format|
      format.html
      format.js
      format.json
      format.csv do
        sheet = CSV.generate(force_quotes: true) do |csv|
          users_labels = @course.course_memberships
                                .includes(:course_labels, :user)
                                .map { |m| [m.user, m.course_labels] }
                                .to_h
          columns = %w[id username last_name first_name email labels]
          columns.concat(@series.map(&:name))
          columns.concat(@series.map { |s| I18n.t('courses.scoresheet.started', series: s.name) })
          csv << columns
          csv << ['Maximum', '', '', '', '', ''].concat(@series.map(&:activity_count)).concat(@series.map(&:activity_count))
          @users.each do |u|
            row = [u.id, u.username, u.first_name, u.last_name, u.email, users_labels[u].map(&:name).join(';')]
            row.concat(@series.map { |s| @hash[[u.id, s.id]][:accepted] })
            row.concat(@series.map { |s| @hash[[u.id, s.id]][:started] })
            csv << row
          end
        end
        filename = "course-#{@course.name.parameterize}.csv"
        send_data(sheet, type: 'text/csv', filename: filename, disposition: 'attachment', x_sendfile: true)
      end
    end
  end

  def questions
    @crumbs = [[@course.name, course_path(@course)], [I18n.t('courses.questions.questions.title'), '#']]

    @refresh = ActiveRecord::Type::Boolean.new.deserialize(params.fetch(:refresh, @course.enabled_questions?.to_s))
    @unanswered = @course.unanswered_questions
                         .reorder(created_at: :asc)
                         .includes(:user, :last_updated_by, submission: [:exercise])
                         .paginate(page: parse_pagination_param(params[:unanswered_page]), per_page: 10)
    @in_progress = @course.in_progress_questions
                          .reorder(updated_at: :desc)
                          .includes(:user, :last_updated_by, submission: [:exercise])
                          .paginate(page: parse_pagination_param(params[:in_progress_page]), per_page: 10)
    @answered = @course.answered_questions
                       .reorder(updated_at: :desc)
                       .includes(:user, :last_updated_by, submission: [:exercise])
                       .paginate(page: parse_pagination_param(params[:answered_page]), per_page: 10)
    count = @course.unanswered_questions.count
    @title = if count == 0
               I18n.t('courses.questions.questions.title')
             else
               I18n.t('courses.questions.questions.page_title', count: count)
             end
    @dot_icon.push(:questions) if @unanswered.any?
  end

  def update_membership
    user = User.find params[:user]
    respond_to do |format|
      if update_membership_status_for user, params[:status]
        toast = t('controllers.updated', model: CourseMembership.model_name.human)
        format.html { redirect_back fallback_location: root_url, notice: toast }
        format.json { head :ok }
        format.js { render 'reload_users', locals: { toast: toast } }
      else
        alert = t('controllers.update_failed', model: CourseMembership.model_name.human)
        format.html { redirect_back(fallback_location: root_url, alert: alert) }
        format.json { head :unprocessable_entity }
        format.js { render 'reload_users', locals: { toast: alert } }
      end
    end
  end

  def unsubscribe
    respond_to do |format|
      if update_membership_status_for current_user,
                                      :unsubscribed
        format.html { redirect_to root_url, notice: I18n.t('courses.registration.unsubscribed_successfully') }
        format.json { head :ok }
      else
        unsubscription_failed_response format
      end
    end
  end

  def subscribe
    redirect_unless_secret_correct if @course.secret_required?(current_user)
    return if performed? # return if redirect happened

    respond_to do |format|
      if current_user.member_of? @course
        format.html { redirect_to(@course) }
        format.json { render json: { errors: ['already subscribed'] }, status: :unprocessable_entity }
      else
        status = nil
        success_method = method(:subscription_succeeded_response)
        if @course.moderated
          status = 'pending'
          success_method = method(:signup_succeeded_response)
        end

        case @course.registration
        when 'open_for_all'
          if try_to_subscribe_current_user status: status
            success_method.call(format)
          else
            subscription_failed_response format
          end
        when 'open_for_institution'
          if @course.institution == current_user.institution
            if try_to_subscribe_current_user status: status
              success_method.call(format)
            else
              subscription_failed_response format
            end
          else
            format.html { redirect_to(course_url(@course, secret: params[:secret]), alert: I18n.t('courses.registration.closed')) }
            format.json { render json: { errors: ['course closed'] }, status: :unprocessable_entity }
          end
        when 'closed'
          format.html { redirect_to(@course, alert: I18n.t('courses.registration.closed')) }
          format.json { render json: { errors: ['course closed'] }, status: :unprocessable_entity }
        end
      end
    end
  end

  def registration
    redirect_to(@course, secret: params[:secret])
  end

  def favorite
    respond_to do |format|
      if @current_membership
        @current_membership.update(favorite: true)
        format.html { redirect_to(@course, alert: I18n.t('courses.favorite.succeeded')) }
        format.json { render :show, status: :created, location: @course }
      else
        format.html { redirect_to(@course, alert: I18n.t('courses.favorite.failed')) }
        format.json { render json: { errors: ['not subscribed to course'] }, status: :unprocessable_entity }
      end
      format.js
    end
  end

  def unfavorite
    respond_to do |format|
      if @current_membership
        @current_membership.update(favorite: false)
        format.html { redirect_to(@course, alert: I18n.t('courses.unfavorite.succeeded')) }
        format.json { head :ok }
      else
        format.html { redirect_to(@course, alert: I18n.t('courses.unfavorite.failed')) }
        format.json { render json: { errors: ['not subscribed to course'] }, status: :unprocessable_entity }
      end
      format.js
    end
  end

  def mass_accept_pending
    @accepted = @course.accept_all_pending
    respond_to do |f|
      f.json
      f.html { redirect_back(fallback_location: course_url(@course)) }
    end
  end

  def mass_decline_pending
    @declined = @course.decline_all_pending
    respond_to do |f|
      f.json
      f.html { redirect_back(fallback_location: course_url(@course)) }
    end
  end

  def reset_token
    @course.generate_secret
    @course.save
    render partial: 'application/token_field', locals: {
      container_name: :hidden_show_link_field,
      name: :hidden_show_link,
      value: course_url(@course, secret: @course.secret),
      reset_url: reset_token_course_path(@course)
    }
  end

  def manage_series
    @crumbs = [[@course.name, course_path(@course)], [I18n.t('courses.show.manage_series'), '#']]
  end

  def reorder_series
    order = JSON.parse(params[:order])
    @course.series.each do |s|
      rank = order.find_index(s.id) || 999
      s.update(order: rank)
    end
  end

  def ical
    @series = Series.where(course_id: @course.id)
  end

  private

  def try_to_subscribe_current_user(**args)
    status = args[:status] || 'student'
    user = current_user

    if @current_membership.present?
      @current_membership.update(status: status)
    else
      membership = CourseMembership.new course: @course,
                                        status: status,
                                        user: user
      membership.save
    end
  end

  def redirect_unless_secret_correct
    if current_user&.member_of?(@course) || current_user&.zeus?
      nil
    elsif params[:secret] != @course.secret
      raise Pundit::NotAuthorizedError, I18n.t('courses.registration.key_mismatch')
    end
  end

  def update_membership_status_for(user, status)
    membership = CourseMembership.where(user: user, course: @course).first
    return false unless membership

    authorize @course, :update_course_admin_membership? if membership.course_admin? && user != current_user
    authorize @course, :update_course_admin_membership? if status == 'course_admin'

    membership.update(status: status).tap do |success|
      if success && membership.unsubscribed?
        membership.favorite = false
        membership.destroy if @course.submissions.where(user: user).empty?
      end
    end
  end

  def signup_succeeded_response(format)
    format.html { redirect_back fallback_location: root_url, notice: I18n.t('courses.registration.sign_up_successfully') }
    format.json { render :show, status: :created, location: @course }
  end

  def subscription_succeeded_response(format)
    format.html { redirect_back(fallback_location: @course, notice: I18n.t('courses.registration.subscribed_successfully')) }
    format.json { render :show, status: :created, location: @course }
  end

  def subscription_failed_response(format)
    format.html { redirect_back fallback_location: root_url, alert: I18n.t('courses.registration.subscription_failed') }
    format.json { render json: @course.errors, status: :unprocessable_entity }
  end

  def unsubscription_failed_response(format)
    format.html { redirect_back fallback_location: root_url, alert: I18n.t('courses.registration.unsubscription_failed') }
    format.json { render json: @course.errors, status: :unprocessable_entity }
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_course_and_current_membership
    @course = Course.find(params[:id])
    @current_membership = CourseMembership.where(course: @course, user: current_user).first
    authorize @course
  end

  def copy_options
    params.require(:copy_options)
          .permit(:base_id,
                  :admins,
                  :hide_series,
                  :exercises,
                  :deadlines)
  end
end
