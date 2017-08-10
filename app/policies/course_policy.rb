class CoursePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.admin?
        scope
      else
        scope.where(visibility: 'visible')
      end
    end
  end

  def index?
    user
  end

  def show?
    if record.hidden?
      user&.admin? || user.member_of?(record)
    else
      true
    end
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
    user&.zeus?
  end

  def list_members?
    course_admin?
  end

  def update_membership?
    course_admin?
  end

  def update_course_admin_membership?
    user&.admin?
  end

  def unsubscribe?
    user
  end

  def subscribe?
    user
  end

  def subscribe_with_secret?
    user
  end

  def scoresheet?
    course_admin?
  end

  def add_series?
    course_admin?
  end

  def permitted_attributes
    if course_admin?
      %i[name year description]
    else
      []
    end
  end

  private

  def course_admin?
    user&.admin? || user&.admin_of?(record)
  end
end
