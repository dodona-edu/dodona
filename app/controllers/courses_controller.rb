class CoursesController < ApplicationController
  before_action :set_course, except: %i[index new create]

  has_scope :by_permission, only: :list_members
  has_scope :by_name, only: :list_members, as: 'filter'

  # GET /courses
  # GET /courses.json
  def index
    authorize Course
    @courses = Course.all
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
        format.html { redirect_back fallback_location: root_url, notice: t('controllers.updated', model: CourseMembership.model_name.human) }
        format.json { head :ok }
      else
        format.html { redirect_back(fallback_location: root_url, alert: t('controllers.update_failed', model: CourseMembership.model_name.human)) }
        format.json { head :unprocessable_entity }
      end
    end
  end

  def unsubscribe
    if update_membership_status_for current_user,
                                    :unsubscribed
      format.html { redirect_to root_url, notice: I18n.t('courses.unsubscribe.unsubscribed_successfully') }
      format.json { head :ok }
    else
      subscription_failed_response format
    end
  end

  def subscribe
    respond_to do |format|
      case @course.registration
      when 'open'
        if try_to_subscribe current_user
          subscription_succeeded_response format
        else
          subscription_failed_response format
        end
      when 'moderated'
        if try_to_subscribe current_user, 'pending'
          signup_succeeded_response format
        else
          subscription_failed_response format
        end
      when 'closed'
        redirect_to(@course, alert: I18n.t('courses.subscribe.key_mismatch'))
      end
    end
  end

  def subscribe_with_secret
    if !current_user
      redirect_to(@course, notice: I18n.t('courses.subscribe.not_logged_in'))
    elsif params[:secret] != @course.secret
      redirect_to(@course, alert: I18n.t('courses.subscribe.key_mismatch'))
    elsif current_user.member_of?(@course)
      redirect_to(@course)
    elsif try_to_subscribe current_user
      respond_to { |f| subscription_failed_response f }
    else
      respond_to { |f| subscription_failed_response f }
    end
  end

  def scoresheet
    sheet = @course.scoresheet
    filename = "scoresheet-#{@course.name.parameterize}.csv"
    send_data(sheet, type: 'text/csv', filename: filename, disposition: 'attachment', x_sendfile: true)
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
             .where(course_memberships: { status: statuses })
             .paginate(page: params[:page])
    render 'users/index'
  end

  private

  def try_to_subscribe(user, status: 'student')
    return false if @course.hidden? && params[:secret] != @course.secret
    if user.unsubscribed_courses.include? @course
      update_membership_status_for user, status
    else
      membership = CourseMembership.new course: @course,
                                        status: status,
                                        user: user
      membership.save
    end
  end

  def update_membership_status_for(user, status)
    membership = CourseMembership.where(user: user,
                                        course: @course)
                                 .first
    return false unless membership
    if membership.status == 'course_admin'
      # There should always be one course administrator
      return false if @course.administrating_members.count <= 1
      authorize @course, :update_course_admin_membership?
    end

    if status == 'course_admin'
      authorize @course, :update_course_admin_membership?
    end

    membership.update(status: status)
  end

  def signup_succeeded_response(format)
    format.html { redirect_to @course, notice: I18n.t('courses.subscribe.subscribed_successfully') }
    format.json { render :show, status: :created, location: @course }
  end

  def subscription_succeeded_response(format)
    format.html { redirect_to @course, notice: I18n.t('courses.subscribe.sign_up_successfully') }
    format.json { render :show, status: :created, location: @course }
  end

  def subscription_failed_response(format)
    format.html { redirect_to @course, alert: I18n.t('courses.subscribe.subscription_failed') }
    format.json { render json: @course.errors, status: :unprocessable_entity }
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_course
    @course = Course.find(params[:id])
    authorize @course
  end
end
