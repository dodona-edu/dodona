class SeriesPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.where(visibility: :open)
      end
    end
  end

  def index?
    user&.zeus?
  end

  def show?
    return true if user&.admin?
    return true if record.open?
    false
  end

  def new?
    user&.admin?
  end

  def edit?
    user&.admin?
  end

  def create?
    user&.admin?
  end

  def update?
    user&.admin?
  end

  def destroy?
    user&.admin?
  end

  def modify_exercises?
    user&.admin?
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
    if user&.admin?
      [:name, :description, :course_id, :visibility, :order, :deadline]
    else
      []
    end
  end
end
