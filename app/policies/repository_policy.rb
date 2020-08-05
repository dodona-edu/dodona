class RepositoryPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.a_course_admin?
        scope.all
      else
        scope.none
      end
    end
  end

  def index?
    user&.admin?
  end

  def show?
    user&.admin?
  end

  def create?
    user&.admin?
  end

  def update?
    user&.zeus?
  end

  def destroy?
    user&.zeus?
  end

  def media?
    true
  end

  def admins?
    user&.repository_admin?(record)
  end

  def add_admin?
    admins?
  end

  def remove_admin?
    admins?
  end

  def courses?
    user&.repository_admin?(record)
  end

  def add_course?
    courses?
  end

  def remove_course?
    courses?
  end

  def hook?
    true
  end

  def reprocess?
    user&.repository_admin?(record)
  end

  def permitted_attributes
    if user&.admin?
      %i[name remote judge_id]
    else
      []
    end
  end
end
