class StatisticsController < ApplicationController
  before_action :set_course
  before_action :set_user

  def index
    unless (current_user.administrating_courses).include? @course || @user == current_user
      raise Pundit::NotAuthorizedError
    end

    submissions = Submission.of_user(@user).in_course(@course)
    submissions_matrix = Hash.new(0)
    submissions.each do |s|
      d = s.created_at.wday - 1
      d = 6 if d == -1
      submissions_matrix[[d, s.created_at.hour]] += 1
    end

    @submissions_aggregate = submissions_matrix.map{|key, val| key.push(val)}

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
