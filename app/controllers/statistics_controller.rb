class StatisticsController < ApplicationController
  before_action :set_user

  def punchcard
    authorize @user
    if params.key? :course_id
      @course = Course.find(params[:course_id])
      punchcard_course_user
    else
      punchcard_user
    end
  end

  def punchcard_user
    all_submissions = []
    @user.subscribed_courses.each do |c|
      matrix = get_submission_matrix @user, c
      matrix.each {|k, v| all_submissions.push({:key => k, :val => v})}
    end

    @result = Hash.new(0)
    all_submissions.each {|h| @result[h[:key]] += h[:val]}

    render json: @result
  end

  def punchcard_course_user
    @submissions_matrix = get_submission_matrix @user, @course
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
  end
end
