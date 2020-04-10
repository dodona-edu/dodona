class ReviewPolicy < ApplicationPolicy
  def review?
    course_admin?
  end

  def review_complete?
    course_admin?
  end

  def course_admin?
    record.class == Review && user&.course_admin?(record&.submission&.course)
  end
end
