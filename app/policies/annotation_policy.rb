class AnnotationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.zeus?
        scope.all
      elsif user
        common = scope.joins(:submission).left_joins(:evaluation)
        common.released.where(submissions: { user: user }).or(common.where(submissions: { course_id: user.administrating_courses.map(&:id) }))
      else
        scope.none
      end
    end
  end

  def index?
    true
  end

  def create?
    record.submission.course.present? && user.course_admin?(record.submission.course)
  end

  def show?
    return false unless SubmissionPolicy.new(user, record.submission).show?
    return true if user&.course_admin?(record&.course)
    return true if record.evaluation.blank?

    record.evaluation.released
  end

  def update?
    record&.user == user
  end

  def destroy?
    record&.user == user
  end

  def transition?(_from, _to = nil)
    false
  end

  def permitted_attributes_for_create
    %i[annotation_text line_nr evaluation_id]
  end

  def permitted_attributes_for_update
    %i[annotation_text]
  end
end
