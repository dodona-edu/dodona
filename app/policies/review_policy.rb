class ReviewPolicy < ApplicationPolicy
  def show?
    course_admin?
  end

  def update?
    course_admin?
  end

  def permitted_attributes
    %i[completed]
  end

  private

  def course_admin?
    user&.course_admin?(record&.submission&.course)
  end
end
