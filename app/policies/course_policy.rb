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
    user&.zeus? or record.is_teacher?(user)
  end

  def create?
    user&.admin?
  end

  def update?
    user&.zeus? or record.is_teacher?(user)
  end

  def destroy?
    user&.zeus?
  end

  def list_members?
    user&.zeus? or record.is_teacher?(user)
  end

  def subscribe?
    user
  end

  def subscribe_with_secret?
    user
  end

  def scoresheet?
    user&.zeus? or record.is_teacher?(user)
  end

  def add_series?
    user&.zeus? or record.is_teacher?(user)
  end

  def toggle_teacher?
    user&.zeus? or record.is_teacher?(user)
  end

  def permitted_attributes
    if user&.admin?
      [:name, :year, :description]
    else
      []
    end
  end
end