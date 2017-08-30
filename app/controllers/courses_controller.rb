class CoursesController < ApplicationController
  before_action :set_course_and_current_membership, except: %i[index new create]

  has_scope :by_permission, only: :list_members
  has_scope :by_name, only: :list_members, as: 'filter'

  # GET /courses
  # GET /courses.json
  def index
    authorize Course
    @courses = policy_scope(Course.all)
    @title = I18n.t('courses.index.title')
  end

  # GET /courses/1
  # GET /courses/1.json
  def show
    @title = @course.name
    @series = policy_scope(@course.series)
    @total_series = @series.count
    @series = @series.limit(5) unless params[:all]
    @series = @series.offset(params[:offset]) if params[:offset]
  end

  # GET /courses/new
  def new
    authorize Course
    @course = Course.new
    @title = I18n.t('courses.new.title')
  end

  # GET /courses/1/edit
  def edit
    @title = @course.name
  end

  # POST /courses
  # POST /courses.json
  def create
    authorize Course
    @course = Course.new(permitted_attributes(Course))

    respond_to do |format|
      if @course.save
        @course.administrating_members << current_user
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
      if @course.update(permitted_attributes(Course))
        format.html { redirect_to @course, notice: I18n.t('controllers.updated', model: Course.model_name.human) }
        format.json { render :show, status: :ok, location: @course }
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

  def update_membership
    user = User.find params[:user]
    respond_to do |format|
      if update_membership_status_for user, params[:status]
        notification = t('controllers.updated', model: CourseMembership.model_name.human)
        format.html { redirect_back fallback_location: root_url, notice: notification }
        format.json { head :ok }
        format.js { render 'reload_users', locals: { notification: notification } }
      else
        alert = t('controllers.update_failed', model: CourseMembership.model_name.human)
        format.html { redirect_back(fallback_location: root_url, alert: alert) }
        format.json { head :unprocessable_entity }
        format.js { render 'reload_users', locals: { notification: alert } }
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
        subscription_failed_response format
      end
    end
  end

  def subscribe
    redirect_unless_secret_correct if @course.hidden?
    return if performed? # return if redirect happenned

    respond_to do |format|
      case @course.registration
      when 'open'
        if try_to_subscribe_current_user
          subscription_succeeded_response format
        else
          subscription_failed_response format
        end
      when 'moderated'
        if try_to_subscribe_current_user status: 'pending'
          signup_succeeded_response format
        else
          subscription_failed_response format
        end
      when 'closed'
        format.html { redirect_to(@course, alert: I18n.t('courses.registration.closed')) }
        format.json { render json: { errors: ['course closed'] }, status: :unprocessable_entity }
      end
    end
  end

  def registration
    @secret = params[:secret]
    redirect_unless_secret_correct
  end

  def scoresheet
    sheet = @course.scoresheet
    filename = "scoresheet-#{@course.name.parameterize}.csv"
    send_data(sheet, type: 'text/csv', filename: filename, disposition: 'attachment', x_sendfile: true)
  end

  def mass_accept_pending
    accepted = @course.accept_all_pending
    render json: { status: 'ok', message: I18n.t('courses.show.mass_accept_notification', count: accepted) }
  end

  def mass_decline_pending
    declined = @course.decline_all_pending
    render json: { status: 'ok', message: I18n.t('courses.show.mass_decline_notification', count: declined) }
  end

  def list_members
    statuses = if %w[unsubscribed pending].include? params[:status]
                 params[:status]
               else
                 %w[course_admin student]
               end

    @users = apply_scopes(@course.users)
             .order('course_memberships.status ASC')
             .order(permission: :desc)
             .order(username: :asc)
             .where(course_memberships: { status: statuses })
             .paginate(page: params[:page])
    @pagination_opts = {
      controller: 'courses',
      action: 'list_members'
    }
    render 'users/index'
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
    if !current_user
      redirect_back(fallback_location: root_url, notice: I18n.t('courses.registration.not_logged_in'))
    elsif params[:secret] != @course.secret
      redirect_back(fallback_location: root_url, alert: I18n.t('courses.registration.key_mismatch'))
    elsif current_user.member_of?(@course)
      redirect_to @course
    end
  end

  def update_membership_status_for(user, status)
    membership = CourseMembership.where(user: user, course: @course).first
    return false unless membership
    if membership.course_admin?
      authorize @course, :update_course_admin_membership? unless user == current_user
    end

    if status == 'course_admin'
      authorize @course, :update_course_admin_membership?
    end

    membership.update(status: status).tap do |success|
      if success && membership.unsubscribed?
        membership.delete if @course.submissions.where(user: user).empty?
      end
    end
  end

  def signup_succeeded_response(format)
    format.html { redirect_back fallback_location: root_url, notice: I18n.t('courses.registration.sign_up_successfully') }
    format.json { render :show, status: :created, location: @course }
  end

  def subscription_succeeded_response(format)
    format.html { redirect_to @course, notice: I18n.t('courses.registration.subscribed_successfully') }
    format.json { render :show, status: :created, location: @course }
  end

  def subscription_failed_response(format)
    format.html { redirect_back fallback_location: root_url, alert: I18n.t('courses.registration.subscription_failed') }
    format.json { render json: @course.errors, status: :unprocessable_entity }
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_course_and_current_membership
    @course = Course.find(params[:id])
    @current_membership = CourseMembership.where(course: @course, user: current_user).first
    authorize @course
  end
end
