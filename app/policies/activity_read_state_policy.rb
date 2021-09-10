class ActivityReadStatePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.zeus?
        scope.all
      elsif user
        scope.of_user(user).or(scope.where(course_id: user.administrating_courses.map(&:id)))
      else
        scope.none
      end
    end
  end

  def index?
    user
  end

  def create?
    user
  end

  def permitted_attributes
    %i[activity_id course_id]
  end
end
