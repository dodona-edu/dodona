class SubmissionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user && user.admin?
        scope.all
      elsif user
        scope.of_user(user)
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

  def create?
    user
  end

  def permitted_attributes
    [:code, :result, :status, :exercise_id]
  end
end
