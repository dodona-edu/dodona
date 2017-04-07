class SeriesPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.zeus?
        scope.all
      elsif user&.admin?
        scope.in_teachers(user)
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
    user&.zeus? or record.is_teacher?(user)
  end

  def edit?
    user&.zeus? or record.is_teacher?(user)
  end

  def create?
    user&.zeus? or record.is_teacher?(user)
  end

  def update?
    user&.zeus? or record.is_teacher?(user)
  end

  def destroy?
    user&.zeus? or record.is_teacher?(user)
  end

  def download_solutions?
    user && token_show?
  end

  def modify_exercises?
    user&.zeus? or record.is_teacher?(user)
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
