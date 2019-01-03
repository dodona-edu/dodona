class StatisticsController < ApplicationController
  def punchcard
    course = nil
    if params.key?(:course_id) && params.key?(:user_id)
      course_membership = CourseMembership.find_by(user_id: params[:user_id], course_id: params[:course_id])
      authorize course_membership
      user = course_membership.user
      course = course_membership.course
    elsif params.key?(:course_id)
      course = Course.find(params[:course_id])
      authorize course
    elsif params.key?(:user_id)
      user = User.find(params[:user_id])
      authorize user
    end
    result = Submission.get_submissions_matrix(user, course)
    Submission.delay(queue: 'statistics').update_submissions_matrix(user, course, result[:latest])
    render json: result[:matrix]
  end
end
