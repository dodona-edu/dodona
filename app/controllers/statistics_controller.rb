class StatisticsController < ApplicationController
  before_action :set_course
  before_action :set_user

  def index
    print @user.id
    print current_user.id
    unless (@user.subscribed_courses & current_user.administrating_courses).include?(@course) || @user == current_user
      raise Pundit::NotAuthorizedError
    end

    submissions_matrix_path = File.join('data', 'aggregates', "#{@course.id}_#{@user.id}.json")

    submissions_matrix = if File.exist?(submissions_matrix_path)
                           JSON.parse File.read submissions_matrix_path
                         else
                           calculate_submissions_matrix submissions_matrix_path
                         end

    @submissions_aggregate = submissions_matrix.map do |key, val|
      key = JSON.parse key
      key.push(val)
    end

  end

  private

  def calculate_submissions_matrix(pathname)
    submissions = Submission.of_user(@user).in_course(@course)
    submissions_matrix = Hash.new(0)
    submissions.each do |s|
      day = created_at.wday > 0 ? created_at.wday - 1 : 6
      submissions_matrix[[day, s.created_at.hour]] += 1
    end

    f = File.new(pathname, 'w')
    f.write(submissions_matrix.to_json)
    f.close

    submissions_matrix
  end

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_user
    @user = User.find(params[:member_id])
    raise ActiveRecord::RecordNotFound unless @user.courses.include? @course
  end
end
