class QuestionPolicy < AnnotationPolicy
  def create?
    all_questions_for_submission = user.questions.where(submission: record.submission)
    total_question_count = all_questions_for_submission.count
    unanswered_question_count = all_questions_for_submission.where(question_state: :unanswered).count
    record.submission.user == user && unanswered_question_count < 5 && total_question_count < 15
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
