class CoursePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.zeus?
        scope
      elsif user
        @scope = scope.joins(:course_memberships)
        scope.where(visibility: :visible_for_all)
            .or(scope.where(institution: user.institution, visibility: :visible_for_institution))
            .or(scope.where(course_memberships: {status: :course_admin, user_id: user.id}))
            .distinct
      else
        scope.where(visibility: :visible_for_all)
      end
    end
  end

  def index?
    user
  end

  def show?
    if record.hidden?
      user&.zeus? || user&.member_of?(record)
    else
      true
    end
  end

  def show_series?
    user&.zeus? ||
        record.open_for_all? ||
        (record.open_for_institution? && record.institution == user.institution) ||
        user&.member_of?(record)
  end

  def create?
    user&.admin?
  end

  def copy?
    create? && show_series?
  end

  def update?
    course_admin?
  end

  def destroy?
    user&.zeus?
  end

  def members?
    course_admin?
  end

  def submissions?
    course_admin?
  end

  def statistics?
    course_admin?
  end

  def update_membership?
    course_admin?
  end

  def update_course_admin_membership?
    user&.zeus? || course_admin?
  end

  def unsubscribe?
    user
  end

  def subscribe?
    user
  end

  def favorite?
    user && user&.member_of?(record)
  end

  def unfavorite?
    user && user&.member_of?(record)
  end

  def registration?
    user
  end

  def scoresheet?
    course_admin?
  end

  def add_series?
    course_admin?
  end

  def mass_accept_pending?
    course_admin?
  end

  def mass_decline_pending?
    course_admin?
  end

  def reset_token?
    course_admin?
  end

  def reorder_series?
    course_admin?
  end

  def punchcard?
    statistics?
  end

  def heatmap?
    statistics?
  end

  def permitted_attributes
    # record is the Course class on create
    if course_admin? || (record == Course && user&.admin?)
      %i[name year description visibility registration color teacher institution_id]
    else
      []
    end
  end

  private

  def course_admin?
    record.class == Course && (user&.course_admin?(record))
  end
end
