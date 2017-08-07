class SeriesPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.admin? || user&.admin_of?(series&.course)
        scope.all
      else
        scope.where(visibility: :open)
      end
    end
  end

  def index?
    user&.zeus?
  end

  def show?
    return true if course_admin?
    return true if record.open?
    false
  end

  def token_show?
    return true if course_admin?
    return true unless record.closed?
    false
  end

  def new?
    user&.admin?
  end

  def edit?
    course_admin?
  end

  def create?
    user&.admin?
  end

  def update?
    course_admin?
  end

  def destroy?
    course_admin?
  end

  def download_solutions?
    user && token_show?
  end

  def modify_exercises?
    course_admin?
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
    course_admin?
  end

  def mass_rejudge?
    course_admin?
  end

  def permitted_attributes
    if course_admin?
      %i[name description course_id visibility order deadline]
    else
      []
    end
  end

  private

  def course_admin?
    user&.admin? || user&.admin_of?(series&.course)
  end
end
