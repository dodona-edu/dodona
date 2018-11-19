class CourseMembersController < ApplicationController
  before_action :set_course
  before_action :set_user, only: [:show]

  has_scope :by_permission
  has_scope :by_filter, as: 'filter'

  def index
    authorize @course, :members?
    statuses = if %w[unsubscribed pending].include? params[:status]
                 params[:status]
               else
                 %w[course_admin student]
               end

    @users = apply_scopes(@course.users)
                 .order('course_memberships.status ASC')
                 .order(permission: :desc)
                 .order(last_name: :asc, first_name: :asc)
                 .where(course_memberships: {status: statuses})
                 .paginate(page: params[:page])

    @pagination_opts = {
        controller: 'course_members',
        action: 'index'
    }

    @title = I18n.t("courses.index.users")
    @crumbs = [[@course.name, course_path(@course)], [I18n.t('courses.index.users'), "#"]]

    respond_to do |format|
      format.json {render 'users/index'}
      format.js {render 'users/index'}
      format.html
    end
  end

  def show
    authorize @user, :show_in_course?
    # We don't have access to the course in the users_controller
    unless (@user.subscribed_courses & current_user.administrating_courses).include?(@course) || current_user.zeus?
      raise Pundit::NotAuthorizedError
    end

    @title = @user.full_name
    @crumbs = [[@course.name, course_path(@course)], [I18n.t('courses.index.users'), course_members_path(@course)], [@user.full_name, '#']]
    @series = policy_scope(@course.series)
    @series_loaded = 5
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_user
    @user = User.find(params[:id])
    unless @user.courses.include? @course
      raise ActiveRecord::RecordNotFound
    end
  end
end
