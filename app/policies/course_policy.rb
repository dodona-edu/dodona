class CoursePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user
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
    user && user.zeus?
  end

  def list_members?
    user && user.admin?
  end

  def subscribe?
    user
  end

  def subscribe_with_secret?
    user
  end

  def add_series?
    user && user.admin?
  end

  def permitted_attributes
    if user && user.admin?
      [:name, :year, :description]
    else
      []
    end
  end
end
