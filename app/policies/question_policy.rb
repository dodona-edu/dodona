class QuestionPolicy < AnnotationPolicy
  def create?
    all_questions_for_submission = user.questions.where(submission: record.submission)
    total_question_count = all_questions_for_submission.count
    unanswered_question_count = all_questions_for_submission.where(question_state: :unanswered).count
    record.submission.user == user && unanswered_question_count < 5 && total_question_count < 15
  end

  def unresolve?
    course_admin? && !record.unanswered?
  end

  def in_progress?
    course_admin? && !record.in_progress?
  end

  def resolved?
    return true if course_admin? && !record.answered?
    return false if record.user != user

    record.unanswered?
  end


  private

  def course_admin?
    user.course_admin? record.submission.course
  end
end
