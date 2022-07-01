class SavedAnnotationPolicy < ApplicationPolicy
  # REMOVE AFTER CLOSED BETA
  BETA_COURSES = [5].freeze

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.zeus?
        scope.all
      elsif user
        # EDIT AFTER CLOSED BETA
        scope.where(user_id: user.id).where(course_id: BETA_COURSES)
      else
        scope.none
      end
    end
  end

  # REMOVE AFTER CLOSED BETA
  def beta_course?(course_id)
    course_id.in? BETA_COURSES
  end

  # REMOVE AFTER CLOSED BETA
  def user_admin_of_beta_course?
    user&.zeus? || user&.administrating_courses&.pluck(:id)&.any? { |c| c.in? BETA_COURSES }
  end

  # REMOVE AFTER CLOSED BETA
  def record_in_beta_course?
    beta_course?(record.course_id)
  end

  def index?
    # EDIT AFTER CLOSED BETA
    user&.a_course_admin? && user_admin_of_beta_course?
  end

  def create?
    # EDIT AFTER CLOSED BETA
    record.course_id.present? && user&.course_admin?(record.course) && user_admin_of_beta_course? && record_in_beta_course?
  end

  def show?
    # EDIT AFTER CLOSED BETA
    record.user_id == user.id && user_admin_of_beta_course? && record_in_beta_course?
  end

  def update?
    # EDIT AFTER CLOSED BETA
    record.user_id == user.id && user_admin_of_beta_course? && record_in_beta_course?
  end

  def destroy?
    # EDIT AFTER CLOSED BETA
    record.user_id == user.id && user_admin_of_beta_course? && record_in_beta_course?
  end

  def permitted_attributes
    %i[title annotation_text]
  end
end
