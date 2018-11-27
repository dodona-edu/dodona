class StatisticsController < ApplicationController
  def punchcard
    course = nil
    if params.key? :course_id
      course_membership = CourseMembership.find_by(user_id: params[:user_id], course_id: params[:course_id])
      authorize course_membership
      user = course_membership.user
      course = course_membership.course
    else
      user = User.find(user_id: params[:user_id])
    end
    render json: Submission.get_submissions_matrix(user, course)
  end
end
