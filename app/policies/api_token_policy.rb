class ApiTokenPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user
  end

  # Actual check happens at UserPolicy.create_tokens?
  def create?
    user
  end

  def destroy?
    return true if user&.admin?

    record.user == user
  end

  def permitted_attributes
    %i[description]
  end
end
