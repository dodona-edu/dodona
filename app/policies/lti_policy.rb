class LabelPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def content_selection?
    current_user&.a_course_admin?
  end

  def redirect?
    true
  end

  def do_redirect?
    true
  end

  def series_and_activities?
    Course.find_by(id: params[:id]).each { |c| current_user&.admin_of?(c) }
  end
end
