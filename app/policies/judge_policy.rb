class JudgePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.admin?
        scope
      else
        scope.none
      end
    end
  end

  def index?
    user&.admin?
  end

  def show?
    user&.admin?
  end

  def create?
    user&.zeus?
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

  def permitted_attributes
    if user&.zeus?
      %i[name image renderer remote]
    else
      []
    end
  end
end
