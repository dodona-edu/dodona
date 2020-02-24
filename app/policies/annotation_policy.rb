class AnnotationPolicy < ApplicationPolicy
  def create?
    record.submission.user == record.user || course_admin?
  end

  def update?
    record.user == user || course_admin?
  end

  def destroy?
    record.user == user || course_admin?
  end

  def permitted_attributes
    attribs = [:annotation_text]
    attribs += [:line_nr] if record == Annotation || record.new_record?
    attribs
  end

  # Record is a submission in this case
  # TODO: Add owner of submission to this.
  def show_comment_button?
    user&.course_admin?(record.course)
  end

  private

  def course_admin?
    record.class == Annotation && user&.course_admin?(record.submission.course)
  end
end
