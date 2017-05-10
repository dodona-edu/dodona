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
    record.teacher?(user)
  end

  def create?
    user&.admin?
  end

  def update?
    record.teacher?(user)
  end

  def destroy?
    user&.zeus?
  end

  def list_members?
    record.teacher?(user) or user.zeus?
  end

  def subscribe?
    user
  end

  def subscribe_with_secret?
    user
  end

  def scoresheet?
    record.teacher?(user)
  end

  def add_series?
    record.teacher?(user)
  end

  def add_teacher?
    record.teacher?(user) or user.zeus?
  end

  def remove_teacher?
    record.teacher?(user) or user.zeus?
  end

  def permitted_attributes
    if user&.admin?
      [:name, :year, :description]
    else
      []
    end
  end
end