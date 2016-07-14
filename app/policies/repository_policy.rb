class RepositoryPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user && user.admin?
  end

  def show?
    user && user.admin?
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

  def permitted_attributes
    if user && user.admin?
      [:name, :remote, :path, :judge_id]
    else
      []
    end
  end
end
