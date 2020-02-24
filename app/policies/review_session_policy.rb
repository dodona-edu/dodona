class ReviewSessionPolicy < ApplicationPolicy
  def show?
    course_admin?
  end

  def edit?
    course_admin?
  end

  def update?
    course_admin?
  end

  def edit?
    course_admin?
  end

  def update?
    course_admin?
  end

  def review?
    course_admin?
  end

  def overview?
    record.reviews.where(user: user).exists? && record.released
  end

  def review_complete?
    course_admin?
  end

  def review_complete?
    course_admin?
  end

  def course_admin?
    record.class == ReviewSession && user&.course_admin?(record&.series&.course)
  end
end
