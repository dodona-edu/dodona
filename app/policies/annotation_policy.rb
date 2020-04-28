class AnnotationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.zeus?
        scope.all
      elsif user
        common = scope.joins(:submission).left_joins(:review_session)
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
    user.course_admin?(record.submission.course)
  end

  def show?
    return false unless SubmissionPolicy.new(user, record.submission).show?
    return true if record.review_session.blank?

    record.review_session.released
  end

  def update?
    record&.user == user
  end

  def destroy?
    record&.user == user
  end

  def permitted_attributes
    if record.class == Annotation
      %i[annotation_text]
    else # new record
      %i[annotation_text line_nr review_session_id]
    end
  end
end
