class CourseMembersController < ApplicationController
  before_action :set_course
  before_action :set_course_membership_and_user, only: %i[show edit update]

  has_scope :by_permission
  has_scope :by_institution, as: 'institution_id'
  has_scope :by_filter, as: 'filter'
  has_scope :by_course_labels, as: 'course_labels', type: :array

  def index
    statuses = if %w[unsubscribed pending].include? params[:status]
                 params[:status]
               else
                 %w[course_admin student]
               end

    @course_memberships = apply_scopes(@course.course_memberships)
                          .includes(:course_labels, user: [:institution])
                          .order(status: :asc)
                          .order(Arel.sql('users.permission ASC'))
                          .order(Arel.sql('users.last_name ASC'), Arel.sql('users.first_name ASC'))
                          .where(status: statuses)
                          .paginate(page: parse_pagination_param(params[:page]))

    @title = I18n.t('courses.index.users')
    @crumbs = [[@course.name, course_path(@course)], [I18n.t('courses.index.users'), '#']]
    @course_labels = CourseLabel.where(course: @course)
  end

  def show
    @title = @user.full_name
    @crumbs = [[@course.name, course_path(@course)], [I18n.t('courses.index.users'), course_members_path(@course)], [@user.full_name, '#']]
    @course_labels = CourseLabel.where(course: @course)
    @series = policy_scope(@course.series)
    @series_loaded = 5
    @users_lables = @course.course_memberships
                           .includes(:course_labels, :user)
                           .map { |m| [m.user, m.course_labels] }
                           .to_h
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

  def download_labels_csv
    csv = @course.labels_csv
    send_data csv[:data],
              type: 'application/csv',
              filename: csv[:filename],
              disposition: 'attachment',
              x_sendfile: true
  end

  def upload_labels_csv
    CSV.foreach(params[:file].path, headers: true) do |row|
      row = row.to_hash
      cm = CourseMembership.find_by(user_id: row['id'], course: @course)
      if cm.present?
        if row['labels'].nil?
          @error = I18n.t('course_members.index.could_not_find_labels_column', user_id: row['id'])
          break
        end
        labels = row['labels'].split(';').map(&:downcase).uniq.map { |name| CourseLabel.find_by(name: name.strip, course: @course) || CourseLabel.create(name: name.strip, course: @course) }
        cm.update(course_labels: labels)
      end
    end
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
