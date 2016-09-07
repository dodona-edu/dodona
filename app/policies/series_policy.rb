class SeriesPolicy < ApplicationPolicy
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
    user && user.zeus?
  end

  def show?
    return true if user && user.admin?
    return true if record.open?
    return false
  end

  def new?
    user && user.admin?
  end

  def edit?
    user && user.admin?
  end

  def create?
    user && user.admin?
  end

  def update?
    user && user.admin?
  end

  def destroy?
    user && user.admin?
  end

  def modify_exercises?
    user && user.admin?
  end

  def add_exercise?
    modify_exercises?
  end

  def remove_exercise?
    modify_exercises?
  end

  def reorder_exercises?
    modify_exercises?
  end

  def permitted_attributes
    if user && user.admin?
      [:name, :description, :course_id, :visibility, :order]
    else
      []
    end
  end
end
