class SavedAnnotationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.zeus?
        scope.all
      elsif user&.a_course_admin?
        scope.where(user_id: user.id)
      else
        scope.none
      end
    end
  end

  def index?
    user&.a_course_admin?
  end

  def create?
    record.course_id.present? && user&.course_admin?(record.course) && record&.user_id == user.id
  end

  def show?
    record&.user_id == user.id
  end

  def new?
    user&.a_course_admin?
  end

  def edit?
    update?
  end

  def update?
    record&.user_id == user.id
  end

  def destroy?
    record&.user_id == user.id
  end

  def permitted_attributes
    %i[title annotation_text]
  end
end
