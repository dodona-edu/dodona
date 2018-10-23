class StatisticsController < ApplicationController
  before_action :set_user

  def punchcard
    if params.key? :course_id
      @course = Course.find(params[:course_id])
      @submissions_matrix = get_submission_matrix @user, @course
    else
      @submissions_matrix = @user.subscribed_courses.map{|c| get_submission_matrix @user, c}
                                 .reduce {|h1, h2| h1.merge(h2) {|_k, v1, v2| v1 + v2}}
    end
    render json: @submissions_matrix
  end

  private

  def get_submission_matrix(user, course)
    unless (@user.subscribed_courses & current_user.administrating_courses).include?(@course) || @user == current_user
      raise Pundit::NotAuthorizedError
    end
    path = File.join('data', 'aggregates', "#{course.id}_#{user.id}.json")
    if File.exist?(path)
      JSON.parse File.read path
    else
      Submission.calculate_submissions_matrix(submissions_matrix_path, user.id, course.id)
    end
  end

  def set_user
    @user = User.find(params[:user_id])
    authorize @user
  end
end
