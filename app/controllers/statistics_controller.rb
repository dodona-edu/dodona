class StatisticsController < ApplicationController
  before_action :set_course_and_user, only: %i[punchcard heatmap]

  def punchcard
    result = Submission.get_punchcard_matrix(@user, @course)
    Submission.delay(queue: 'statistics').update_punchcard_matrix(@user, @course)
    render json: result[:matrix]
  end

  def heatmap
    result = Submission.get_heatmap_matrix(@user, @course)
    Submission.delay(queue: 'statistics').update_heatmap_matrix(@user, @course)
    render json: result[:matrix]
  end

  private

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
