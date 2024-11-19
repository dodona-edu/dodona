class CourseMembersController < ApplicationController
  include HasFilter
  before_action :set_course
  before_action :set_course_membership_and_user, only: %i[show edit update]

  has_scope :by_permission
  has_scope :by_filter, as: 'filter'
  has_filter :course_labels, multi: true
  has_filter :institution_id

  has_scope :order_by, using: %i[column direction], type: :hash do |controller, scope, value|
    column, direction = value
    if %w[ASC DESC].include?(direction)
      if %w[status_in_course_and_name].include?(column)
        scope.send "order_by_#{column}", direction
      elsif column == 'progress'
        course = Course.find(controller.params[:course_id])
        scope.order_by_progress direction, course
      else
        scope
      end
    else
      scope
    end
  end

  def index
    statuses = if %w[unsubscribed pending].include? params[:status]
                 params[:status]
               else
                 %w[course_admin student]
               end

    @course_memberships = @course.course_memberships
                                 .order_by_status_in_course_and_name('ASC')
                                 .where(status: statuses)
    @filters = filters(@course_memberships)
    @course_memberships = apply_scopes(@course_memberships)
                          .includes(:course_labels, user: [:institution])

    @title = I18n.t('courses.index.users')
    @crumbs = [[@course.name, course_path(@course)], [I18n.t('courses.index.users'), '#']]

    respond_to do |format|
      format.html do
        @course_memberships = @course_memberships.paginate(page: parse_pagination_param(params[:page]))
      end
      format.js do
        @course_memberships = @course_memberships.paginate(page: parse_pagination_param(params[:page]))
      end
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=\"#{@course.name} - #{I18n.t('courses.index.users')}.csv\""
      end
    end
  end

  def show
    @title = @user.full_name
    @crumbs = [[@course.name, course_path(@course)], [I18n.t('courses.index.users'), course_members_path(@course)], [@user.full_name, '#']]
    @course_labels = CourseLabel.where(course: @course)
    @series = policy_scope(@course.series)
    @series_loaded = 5
  end

  def edit
    @title = @user.full_name
    @crumbs = [[@course.name, course_path(@course)], [I18n.t('courses.index.users'), course_members_path(@course)], [@user.full_name, course_member_path(@course, @user)], [I18n.t('crumbs.edit'), '#']]
    @course_labels = CourseLabel.where(course: @course)
  end

  def update
    attributes = permitted_attributes(@course_membership)

    course_labels = attributes[:course_labels]
    if course_labels
      course_labels = course_labels.split(',') unless course_labels.is_a?(Array)
      attributes[:course_labels] = course_labels&.map(&:downcase)&.uniq&.map { |name| CourseLabel.find_by(course: @course, name: name) || CourseLabel.create(course: @course, name: name) }
    end

    if @course_membership.update(attributes)
      redirect_to course_member_path(@course, @user), flash: { success: I18n.t('controllers.updated', model: CourseMembership.model_name.human) }
    else
      render :edit
    end
  end

  def upload_labels_csv
    return render json: { message: I18n.t('course_members.upload_labels_csv.no_file') }, status: :unprocessable_entity if params[:file] == 'undefined'

    begin
      headers = CSV.foreach(params[:file].path).first
      %w[id labels].each do |column|
        return render json: { message: I18n.t('course_members.upload_labels_csv.missing_column', column: column) }, status: :unprocessable_entity unless headers&.include?(column)
      end

      CSV.foreach(params[:file].path, headers: true) do |row|
        row = row.to_hash
        cm = CourseMembership.find_by(user_id: row['id'], course: @course)
        if cm.present?
          if row['labels'].nil?
            @error = I18n.t('course_members.index.could_not_find_labels_column', user_id: row['id'])
            return render json: { message: @error }, status: :unprocessable_entity
          end
          labels = row['labels'].split(';').map(&:downcase).uniq.map { |name| CourseLabel.find_by(name: name.strip, course: @course) || CourseLabel.create(name: name.strip, course: @course) }
          cm.update(course_labels: labels)
        end
      end
    rescue CSV::MalformedCSVError
      return render json: { message: I18n.t('course_members.upload_labels_csv.malformed') }, status: :unprocessable_entity
    end

    render json: {}, status: :ok
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
    authorize @course, :members?
  end

  def set_course_membership_and_user
    @course_membership = CourseMembership.find_by!(course_id: params[:course_id], user_id: params[:id])
    @user = @course_membership.user
    authorize @course_membership
  end
end
