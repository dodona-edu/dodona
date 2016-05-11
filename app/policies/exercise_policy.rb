class ExercisePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user && user.admin?
        scope.all
      else
        scope.where(visibility: :open)
      end
    end
  end

  def index?
    true
  end

  def show?
    !record.closed? || (user && user.admin?)
  end

  def edit?
    user && user.admin?
  end

  def update?
    user && user.admin?
  end

  def users?
    user && user.admin?
  end

  def permitted_attributes
    if user && user.admin?
      [:visibility]
    else
      []
    end
  end
end
