class CoursePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user
  end

  def show?
    true
  end

  def new?
    user&.admin?
  end

  def edit?
    user&.admin?
  end

  def create?
    user&.admin?
  end

  def update?
    user&.admin?
  end

  def destroy?
    user&.zeus?
  end

  def list_members?
    user&.admin?
  end

  def update_membership
    user&.admin?
  end

  def unsubscribe
    user
  end

  def subscribe?
    user
  end

  def subscribe_with_secret?
    user
  end

  def scoresheet?
    user&.admin?
  end

  def add_series?
    user&.admin?
  end

  def permitted_attributes
    if user&.admin?
      %i[name year description]
    else
      []
    end
  end
end
