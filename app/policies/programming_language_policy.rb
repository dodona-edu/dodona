class ProgrammingLanguagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    user&.admin?
  end

  def show?
    user&.admin?
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
      %i[name extension editor_name renderer_name icon]
    else
      []
    end
  end
end
