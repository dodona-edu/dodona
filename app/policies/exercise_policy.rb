class ExercisePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user && user.admin?
        scope.all
      else
        scope.where(visibility: :open).where(status: :ok)
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

  def media?
    show?
  end

  def permitted_attributes
    if user && user.admin?
      [:visibility, :name_nl, :name_en]
    else
      []
    end
  end
end
