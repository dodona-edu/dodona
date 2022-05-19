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

  def info?
    # This is checked correctly in the ActivityPolicy
    true
  end

  def overview?
    show? && (record.activities_visible || course_admin?)
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

  def modify_activities?
    course_admin?
  end

  def add_activity?
    modify_activities?
  end

  def remove_activity?
    modify_activities?
  end

  def reorder_activities?
    modify_activities?
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

  def export?
    return true if zeus?

    course_member?
  end

  def create_evaluation?
    course_admin?
  end

  def permitted_attributes
    # record is the Series class on create
    if course_admin? || record == Series
      %i[name description course_id visibility order deadline indianio_support progress_enabled activities_visible]
    else
      []
    end
  end

  def course_admin?
    record.instance_of?(Series) && user&.course_admin?(record&.course)
  end

  def statistics?
    course_admin?
  end

  def violin?
    statistics?
  end

  def stacked_status?
    statistics?
  end

  def cumulative_timeseries?
    statistics?
  end

  def timeseries?
    statistics?
  end

  def show_progress?
    record.instance_of?(Series) && (record.progress_enabled || course_admin?)
  end

  private

  def course_member?
    record.instance_of?(Series) && user&.member_of?(record&.course)
  end
end
