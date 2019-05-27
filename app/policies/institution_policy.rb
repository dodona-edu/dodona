class InstitutionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    zeus?
  end

  def show?
    zeus?
  end

  def edit?
    zeus?
  end

  def update?
    zeus?
  end

  def permitted_attributes
    if zeus?
      [:name, :short_name]
    else
      []
    end
  end
end
