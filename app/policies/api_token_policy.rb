class ApiTokenPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user
  end

  def create?
    return false unless user
    return true if user.admin?
    record.user == user
  end

  def destroy?
    create?
  end

  def permitted_attributes
    %i[description]
  end
end
