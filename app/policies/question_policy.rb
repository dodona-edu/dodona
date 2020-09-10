class QuestionPolicy < AnnotationPolicy
  def create?
    # If there is no course, don't allow questions.
    return false if record.submission.course.nil?
    return false unless record.submission.course.enabled_questions?

    # Only the submitter (ie. the student) may create questions.
    record.submission.user == user
  end

  def unresolve?
    return false if record.unanswered? || !transition?

    user.course_admin?(record.submission.course)
  end

  def in_progress?
    return false if record.in_progress? || !transition?

    user.course_admin?(record.submission.course)
  end

  def resolve?
    return false if record.answered? || !transition?

    user.course_admin?(record.submission.course) || record.user == user
  end

  def update?
    # Don't allow editing if the question was answered.
    return false if record.answered?

    record&.user == user
  end

  def destroy?
    # Don't allow removing if the question was answered.
    return false if record.answered?

    record&.user == user
  end

  private

  def transition?
    return true if record.transition_from.blank?

    record.question_state.to_s == record.transition_from
  end
end
