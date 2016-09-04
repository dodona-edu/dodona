class SeriesPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user && user.admin?
  end

  def show?
    true
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

  def add_exercise?
    user && user.admin?
  end

  def permitted_attributes
    if user && user.admin?
      [:name, :description, :course_id, :visibility, :order]
    else
      []
    end
  end
end
