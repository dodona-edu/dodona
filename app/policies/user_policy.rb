class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user && user.admin?
  end

  def show?
    user && (user.admin? || user.id == record.id)
  end

  def new?
    user && user.zeus?
  end

  def edit?
    user && user.zeus?
  end

  def create?
    user && user.zeus?
  end

  def update?
    user && user.zeus?
  end

  def destroy?
    user && user.zeus?
  end
end
