class RubricPolicy < ApplicationPolicy
  def update?
    course_admin?
  end

  def create?
    course_admin?
  end

  def destroy?
    course_admin?
  end

  def add_all?
    course_admin?
  end

  def permitted_attributes_for_create
    %i[evaluation_exercise_id maximum name visible description]
  end

  def permitted_attributes_for_update
    %i[maximum name visible description]
  end

  private

  def course_admin?
    course = record&.evaluation_exercise&.evaluation&.series&.course
    user&.course_admin?(course)
  end
end
