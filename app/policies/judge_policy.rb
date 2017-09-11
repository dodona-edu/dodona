class JudgePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user&.admin?
  end

  def show?
    user&.admin?
  end

  def create?
    user&.admin?
  end

  def update?
    user&.admin?
  end

  def destroy?
    user&.zeus?
  end

  def hook?
    true
  end

  def permitted_attributes
    if user&.admin?
      %i[name image renderer runner remote]
    else
      []
    end
  end
end
