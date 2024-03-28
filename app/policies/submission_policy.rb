class SubmissionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.zeus?
        scope.all
      elsif user
        scope.of_user(user).or(scope.where(course_id: user.administrating_courses.map(&:id)))
      else
        scope.none
      end
    end
  end

  def index?
    user
  end

  def show?
    user && ((user == record.user) || course_admin?)
  end

  def download?
    user && ((user == record.user) || course_admin?)
  end

  def evaluate?
    course_admin?
  end

  def create?
    user.present?
  end

  def edit?
    user && ((user == record.user) || course_admin?)
  end

  def mass_rejudge?
    user&.a_course_admin?
  end

  def media?
    show?
  end

  def permitted_attributes
    %i[code exercise_id course_id]
  end

  private

  def course_admin?
    record.instance_of?(Submission) && user&.course_admin?(record&.course)
  end
end
