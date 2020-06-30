class QuestionPolicy < AnnotationPolicy
  def create?
    record.submission.user == user
  end

  def resolvable?
    record.user == user && !record.answered?
  end

  def resolved?
    record.user == user || course_admin?
  end

  def in_progress?
    course_admin?
  end

  private

  def course_admin?
    user.course_admin? record.submission.course
  end

end
