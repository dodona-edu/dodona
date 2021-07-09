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

  def merge?
    zeus?
  end

  def merge_changes?
    zeus?
  end

  def do_merge?
    zeus?
  end

  def permitted_attributes
    if zeus?
      [:name, :short_name, { providers_attributes: %i[id mode] }]
    else
      []
    end
  end
end
