class VersionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.zeus?
        scope
      else
        scope.where(draft: false)
      end
    end
  end

  def index?
    true
  end

  def update?
    user&.zeus?
  end

  def create?
    user&.zeus?
  end

  def destroy?
    user&.zeus?
  end

  def permitted_attributes
    if user&.zeus?
      %i[tag notes draft release]
    else
      %i[]
    end
  end
end
