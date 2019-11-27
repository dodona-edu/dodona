class SeriesPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.zeus?
        scope.all
      elsif user
        @scope = scope.joins(course: :course_memberships)
        scope.where(visibility: :open)
             .or(scope.where(course: { course_memberships: { status: :course_admin, user_id: user.id } }))
             .distinct
      else
        scope.where(visibility: :visible)
      end
    end
  end

  def index?
    user
  end

  def show?
    return true if course_admin?
    return false if record.closed?
    return false if record.hidden? && user.nil?

    course = record.course
    course.visible_for_all? ||
      (course.visible_for_institution? && course.institution == user&.institution) ||
      user&.member_of?(course)
  end

  def overview?
    show? && (record.exercises_visible || course_admin?)
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

  def download_submissions?
    user && show?
  end

  def indianio_download?
    true
  end

  def modify_exercises?
    course_admin?
  end

  def add_exercise?
    modify_exercises?
  end

  def remove_exercise?
    modify_exercises?
  end

  def reorder_exercises?
    modify_exercises?
  end

  def scoresheet?
    course_admin?
  end

  def scoresheet_download?
    course_admin?
  end

  def mass_rejudge?
    course_admin?
  end

  def reset_token?
    edit?
  end

  def permitted_attributes
    # record is the Series class on create
    if course_admin? || record == Series
      %i[name description course_id visibility order deadline indianio_support progress_enabled exercises_visible]
    else
      []
    end
  end

  private

  def course_admin?
    record.class == Series && user&.course_admin?(record&.course)
  end
end
