class ReviewSessionPolicy < ApplicationPolicy
  def show?
    course_admin?
  end

  def create?
    course_admin?
  end

  def update?
    course_admin?
  end

  def destroy?
    course_admin?
  end

  def permitted_attributes
    if record.class == ReviewSession
      %i[released deadline user_ids exercise_ids]
    else
      %i[series_id deadline user_ids exercise_ids]
    end
  end

  private

  def course_admin?
    user&.course_admin?(record&.series&.course)
  end
end
