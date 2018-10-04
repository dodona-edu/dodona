class CourseMembersController < ApplicationController
  before_action :set_course
  before_action :set_user, only: [:show]

  has_scope :by_permission
  has_scope :by_name, as: 'filter'

  def index
     statuses = if %w[unsubscribed pending].include? params[:status]
                 params[:status]
               else
                 %w[course_admin student]
               end

    @users = apply_scopes(@course.users)
             .order('course_memberships.status ASC')
             .order(permission: :desc)
             .order(last_name: :asc, first_name: :asc)
             .where(course_memberships: { status: statuses })
             .paginate(page: params[:page])

    @pagination_opts = {
      controller: 'course_members',
      action: 'index'
    }

    @title = I18n.t("courses.index.users")
    @crumbs = [[I18n.t('courses.index.title'), courses_path], [@course.name, course_path(@course)], [I18n.t('courses.index.users'), "#"]]

    respond_to do |format|
      format.json { render 'users/index' }
      format.js { render 'users/index' }
      format.html
    end
  end

  def show
    @title = @user.full_name
    @crumbs = [[I18n.t('courses.index.title'), courses_path], [@course.name, course_path(@course)], [I18n.t('courses.index.users'), course_members_path(@course)], [@user.full_name, '#']]
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
    authorize @course, :members?
  end

  def set_user
    @user = User.find(params[:id])
    unless @user.courses.include? @course
      raise ActiveRecord::RecordNotFound
    end
  end
end
