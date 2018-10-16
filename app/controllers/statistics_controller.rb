class StatisticsController < ApplicationController
  before_action :set_course
  before_action :set_user

  def index
    unless (current_user.administrating_courses).include? @course || @user == current_user
      raise Pundit::NotAuthorizedError
    end

    submissions_matrix_path = File.join('data', 'aggregates', "#{@course.id}_#{@user.id}.json")
    submissions_matrix = JSON.parse File.read submissions_matrix_path

    @submissions_aggregate = submissions_matrix.map do |key, val|
      key = JSON.parse key
      key.push(val)
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_user
    @user = User.find(params[:member_id])
    unless @user.courses.include? @course
      raise ActiveRecord::RecordNotFound
    end
  end
end
