class SubmissionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.admin?
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
    user && ((user == record.user) || user.admin?)
  end

  def download?
    user && ((user == record.user) || user.admin?)
  end

  def evaluate?
    user&.admin?
  end

  def create?
    user
  end

  def edit?
    user && ((user == record.user) || user.admin?)
  end

  def mass_rejudge?
    user&.admin?
  end

  def media?
    show?
  end

  def permitted_attributes
    %i[code exercise_id course_id]
  end
end
