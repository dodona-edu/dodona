class AnnotationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.zeus?
        scope.all
      elsif user
        scope = scope.joins(:submission)
        scope.where(submission: { user: user }).or(scope.where(submission: { course_id: user.administrating_courses.map(&:id) }))
      else
        scope.none
      end
    end
  end

  def index?
    true
  end

  def create?
    if record.class == Annotation
      user.course_admin?(record.submission.course)
    else
      user.a_course_admin?
    end
  end

  def show?
    policy(record.submission).show?
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
      %i[annotation_text line_nr]
    end
  end
end
