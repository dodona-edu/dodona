class SeriesPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.zeus?
        scope.all
      elsif user&.admin?
        scope.in_teachers(user) or scope.where(visibility: :open)
      else
        scope.where(visibility: :open)
      end
    end
  end

  def index?
    user&.zeus?
  end

  def show?
    return true if user&.admin?
    return true if record.open?
    false
  end

  def token_show?
    return true if user&.admin?
    return true unless record.closed?
    false
  end

  def new?
    record.in_teachers(user)
  end

  def edit?
    record.teacher?(user)
  end

  def create?
    record.in_teachers(user)
  end

  def update?
    record.teacher?(user)
  end

  def destroy?
    record.teacher?(user)
  end

  def download_solutions?
    user && token_show?
  end

  def modify_exercises?
   record.teacher?(user)
  end

  def add_exercise?
    modify_exercises?
  end

  def remove_exercise?
    modify_exercises?
  end

  def reorder_exercises?
    modify_exercises?
  end

  def scoresheet?
    user&.zeus?
  end

  def permitted_attributes
    if user&.admin?
      [:name, :description, :course_id, :visibility, :order, :deadline]
    else
      []
    end
  end
end