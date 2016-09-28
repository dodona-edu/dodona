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

  def new?
    user&.admin?
  end

  def edit?
    user&.zeus?
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

  def hook?
    true
  end

  def reprocess?
    user&.admin?
  end

  def permitted_attributes
    if user&.admin?
      [:name, :remote, :path, :judge_id]
    else
      []
    end
  end
end
