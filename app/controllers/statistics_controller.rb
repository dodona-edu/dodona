class StatisticsController < ApplicationController
  before_action :set_course_and_user, only: %i[punchcard heatmap]

  def punchcard
    result = Submission.punchcard_matrix(user: @user, course: @course, timezone: Time.zone)
    Submission.delay(queue: 'statistics').update_punchcard_matrix(user: @user, course: @course, timezone: Time.zone)
    if result.present?
      render json: result[:value]
    else
      render json: { status: 'not available yet' }, status: :accepted
    end
  end

  def heatmap
    result = Submission.heatmap_matrix(user: @user, course: @course)
    Submission.delay(queue: 'statistics').update_heatmap_matrix(user: @user, course: @course)
    if result.present?
      render json: result[:value]
    else
      render json: { status: 'not available yet' }, status: :accepted
    end
  end

  def violin
    visualise_series(:violin_matrix)
  end

  def stacked_status
    visualise_series(:stacked_status_matrix)
  end

  def timeseries
    visualise_series(:timeseries_matrix)
  end

  def cumulative_timeseries
    visualise_series(:cumulative_timeseries_matrix)
  end

  private

  def visualise_series(visualisation)
    series = Series.find(params[:series_id])
    authorize series

    result = Submission.send(visualisation, series: series, deadline: series.deadline)
    if result.present?
      ex_data = series.exercises.map { |ex| [ex.id, ex.name] }
      data = result[:value].map { |k, v| { ex_id: k, ex_data: v } }
      render json: { data: data, exercises: ex_data, student_count: series.course.enrolled_members.length }
    else
      render json: { status: 'not available yet' }, status: :accepted
    end
  end

  def set_course_and_user
    @user = nil
    @course = nil
    if params.key?(:course_id) && params.key?(:user_id)
      course_membership = CourseMembership.find_by(user_id: params[:user_id], course_id: params[:course_id])
      authorize course_membership
      @user = course_membership.user
      @course = course_membership.course
    elsif params.key?(:course_id)
      @course = Course.find(params[:course_id])
      authorize @course
    elsif params.key?(:user_id)
      @user = User.find(params[:user_id])
      authorize @user
    end
  end
end
