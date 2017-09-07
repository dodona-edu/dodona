class SeriesPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        admin = CourseMembership.statuses['course_admin']
        open = Series.visibilities['open']
        scope.joins(course: :course_memberships)
             .where(
               <<~SQL
                 series.visibility              = #{open}
                 OR  course_memberships.status  = #{admin}
                 AND course_memberships.user_id = #{user.id}
               SQL
             ).distinct
      end
    end
  end

  def index?
    user&.zeus?
  end

  def show?
    return true if course_admin?
    return false unless record.open?
    course = record.course
    course.visible? || user.member_of?(course)
  end

  def overview?
    show?
  end

  def token_show?
    return true if course_admin?
    return true unless record.closed?
    false
  end

  def new?
    user&.admin?
  end

  def edit?
    course_admin?
  end

  def create?
    user&.admin?
  end

  def update?
    course_admin?
  end

  def destroy?
    course_admin?
  end

  def download_solutions?
    user && token_show?
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

  def mass_rejudge?
    course_admin?
  end

  def reset_token?
    edit?
  end

  def permitted_attributes
    # record is the Series class on create
    if course_admin? ||
       (record == Series && user&.admin?)
      %i[name description course_id visibility order deadline indianio_support]
    else
      []
    end
  end

  private

  def course_admin?
    user&.zeus? ||
      (record.class == Series &&
       user&.admin_of?(record&.course))
  end
end
