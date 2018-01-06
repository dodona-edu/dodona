class ApiTokenPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user
  end

  # Actual check happends at UserPolicy.create_tokens?
  def create?
    user
  end

  def destroy?
    user&.admin?
    record.user == user
  end

  def permitted_attributes
    %i[description]
  end
end
