class QuestionPolicy < AnnotationPolicy
  def create?
    # If there is no course, don't allow questions.
    return false if record.submission.course.nil?
    return false unless record.submission.course.enabled_questions?
    return false unless record.submission.user == user

    all_questions_for_submission = user.questions.where(submission: record.submission)
    total_question_count = all_questions_for_submission.count
    unanswered_question_count = all_questions_for_submission.where(question_state: :unanswered).count
    unanswered_question_count < 5 && total_question_count < 15
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

  private

  def transition?
    return true if record.transition_from.blank?

    record.question_state.to_s == record.transition_from
  end
end
