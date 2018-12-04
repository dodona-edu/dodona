class CourseMembershipPolicy < ApplicationPolicy
  def show?
    user&.course_admin?(record.course)
  end

  def update?
    user&.course_admin?(record.course)
  end

  def punchcard?
    show?
  end

  def permitted_attributes
    if user&.course_admin?(record.course)
      %i[course_labels]
    else
      []
    end
  end
end
