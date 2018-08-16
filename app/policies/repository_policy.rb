class RepositoryPolicy < ApplicationPolicy
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
    user&.zeus?
  end

  def destroy?
    user&.zeus?
  end

  def admins?
    user&.repository_admin?(record)
  end

  def hook?
    true
  end

  def reprocess?
    user&.repository_admin?(record)
  end

  def permitted_attributes
    if user&.admin?
      %i[name remote judge_id]
    else
      []
    end
  end
end
