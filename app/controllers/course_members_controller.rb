class CourseMembersController < ApplicationController
  before_action :set_course
  before_action :set_course_membership_and_user, only: [:show, :edit, :update]

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
    @title = @user.full_name
    @crumbs = [[@course.name, course_path(@course)], [I18n.t('courses.index.users'), course_members_path(@course)], [@user.full_name, '#']]
    @series = policy_scope(@course.series)
    @series_loaded = 5
  end

  def edit
    @title = @user.full_name
    @crumbs = [[@course.name, course_path(@course)], [I18n.t('courses.index.users'), course_members_path(@course)], [@user.full_name, course_member_path(@course, @user)], [I18n.t("crumbs.edit"), '#']]
    @course_labels = CourseLabel.where(course: @course)
  end

  def update
    attributes = permitted_attributes(@course_membership)

    course_labels = attributes[:course_labels]
    if course_labels
      unless course_labels.is_a?(Array)
        course_labels = course_labels.split(',')
      end
      attributes[:course_labels] = course_labels&.map {|name| CourseLabel.find_by(course: @course, name: name) || CourseLabel.create(course: @course, name: name)}
    end

    if @course_membership.update(attributes)
      redirect_to course_member_path(@course, @user), flash: {success: I18n.t('controllers.updated', model: CourseMembership.model_name.human)}
    else
      render :edit
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_course_membership_and_user
    @course_membership = CourseMembership.find_by!(course_id: params[:course_id], user_id: params[:id])
    @user = @course_membership.user
    authorize @course_membership
  end
end
