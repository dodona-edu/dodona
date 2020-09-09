class QuestionPolicy < AnnotationPolicy
  def create?
    return false unless record.submission.course.enabled_questions?

    all_questions_for_submission = user.questions.where(submission: record.submission)
    total_question_count = all_questions_for_submission.count
    unanswered_question_count = all_questions_for_submission.where(question_state: :unanswered).count
    record.submission.user == user && unanswered_question_count < 5 && total_question_count < 15
  end

  def unresolve?
    return false if record.unanswered? || !transition?

    user.course_admin?(record.submission.course)
  end

  def in_progress?
    return false if record.in_progress? || !transition?

    user.course_admin?(record.submission.course) && !record.in_progress?
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
