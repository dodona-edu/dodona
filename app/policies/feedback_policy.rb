class FeedbackPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.zeus?
        scope.all
      elsif user
        scope.joins(:evaluation_user).where(evaluation_users: { user: user })
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
    %i[completed submission_id]
  end

  private

  def course_admin?
    user&.course_admin?(record&.evaluation&.series&.course)
  end
end
