class ActivityReadStatesController < ApplicationController
  include SeriesHelper

  before_action :set_activity_read_states, only: %i[index]

  has_scope :by_filter, as: 'filter' do |controller, scope, value|
    scope.by_filter(value, skip_user: controller.params[:user_id].present?, skip_content_page: controller.params[:activity_id].present?)
  end

  has_scope :by_course_labels, as: 'course_labels', type: :array do |controller, scope, value|
    course = Course.find_by(id: controller.params[:course_id]) if controller.params[:course_id].present?
    if course.present? && controller.current_user&.course_admin?(course) && controller.params[:user_id].nil?
      scope.by_course_labels(value, controller.params[:course_id])
    else
      scope
    end
  end

  def index
    authorize ActivityReadState
    @read_states = @read_states.paginate(page: parse_pagination_param(params[:page]))

    @title = I18n.t('activity_read_states.index.title')
    @submissions_path = submissions_path
    @crumbs = []
    if @user
      @crumbs << if @course.present?
                   [@user.full_name, course_member_path(@course, @user)]
                 else
                   [@user.full_name, user_path(@user)]
                 end
      @submissions_path = user_submissions_path(@user)
    elsif @series
      @crumbs << [@series.course.name, course_path(@series.course)] << [@series.name, breadcrumb_series_path(@series, current_user)]
      @submissions_path = nil
    elsif @course
      @crumbs << [@course.name, course_path(@course)]
      @submissions_path = course_submissions_path(@course)
    end
    @crumbs << [@content_page.name, helpers.activity_scoped_path(activity: @content_page, series: @series, course: @course)] if @content_page
    @crumbs << [I18n.t('activity_read_states.index.title'), '#']
  end

  def create
    authorize ActivityReadState
    args = permitted_attributes(ActivityReadState)
    args[:user_id] = current_user.id
    course = Course.find(args[:course_id]) if args[:course_id].present?
    args.delete[:course_id] if args[:course_id].present? && course.subscribed_members.exclude?(current_user)
    read_state = ActivityReadState.new args
    can_read = Pundit.policy!(current_user, read_state.activity).read?
    if can_read && read_state.save
      respond_to do |format|
        format.js { render 'activities/read', locals: { activity: read_state.activity, course: read_state.course, read_state: read_state, user: current_user } }
        format.json { head :ok }
      end
    else
      render json: { status: 'failed', errors: read_state.errors }, status: :unprocessable_entity
    end
  end

  private

  def set_activity_read_states
    @read_states = apply_scopes(policy_scope(ActivityReadState))

    if params[:user_id]
      @user = User.find(params[:user_id])
      @read_states = @read_states.of_user(@user)
    end

    if params[:course_id]
      @course = Course.find(params[:course_id])
      @course_labels = CourseLabel.where(course: @course) if @user.blank? && current_user&.course_admin?(@course)
    end

    @series = Series.find(params[:series_id]) if params[:series_id]
    @activity = ContentPage.find(params[:activity_id]) if params[:activity_id]

    if @activity
      @read_states = @read_states.of_content_page(@activity)
      if @course
        @read_states = @read_states.in_course(@course)
      elsif @series
        @read_states = @read_states.in_course(@series.course)
      end
    elsif @series
      @read_states = @read_states.in_series(@series)
    elsif @course
      @read_states = @read_states.in_course(@course)
    end

    @course_membership = CourseMembership.find_by(user: @user, course: @course) if @user.present? && @course.present?
  end
end
