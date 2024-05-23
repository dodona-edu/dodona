class SeriesUsersController < ApplicationController
  has_scope :by_institution, as: 'institution_id'
  has_scope :by_filter, as: 'filter'
  has_scope :by_course_labels, as: 'course_labels', type: :array do |controller, scope, value|
    scope.by_course_labels(value, Series.find(controller.params[:series_id]).course_id)
  end
  def index
    @series = Series.find(params[:series_id])
    @users = apply_scopes(@series.course.enrolled_members)
    @course_labels = CourseLabel.where(course: @series.course)
  end

  def create
    user_id = params[:user_id]
    series_id = params[:series_id]
    series_user = SeriesUser.new(user_id: user_id, series_id: series_id)
    if series_user.save
      render json: { status: :ok }
    else
      render json: { status: :error, errors: series_user.errors.full_messages }
    end
  end

  def destroy
    id = params[:id]
    series_user = SeriesUser.find(id)
    if series_user&.destroy
      render json: { status: :ok }
    else
      render json: { status: :error, errors: series_user.errors.full_messages }
    end
  end

  def destroy_all
    @series = Series.find(params[:series_id])
    @series.series_users.destroy_all
    redirect_to series_series_users_path(@series)
  end

  def create_all
    @series = Series.find(params[:series_id])
    @users = apply_scopes(@series.course.enrolled_members)
    @users.each do |user|
      SeriesUser.create(user_id: user.id, series_id: @series.id)
    end
  end
end
