class SubmissionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.admin?
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

  def evaluate?
    user&.admin?
  end

  def create?
    user
  end

  def edit?
    user && ((user == record.user) || user.admin?)
  end

  def media?
    show?
  end

  def permitted_attributes
    [:code, :exercise_id]
  end
end
