class ReviewPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.zeus?
        scope.all
      elsif user
        scope.joins(:review_user).where(review_users: { user: user })
      else
        scope.none
      end
    end
  end

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
