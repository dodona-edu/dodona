class QuestionPolicy < AnnotationPolicy
  def create?
    record.submission.user == user
  end
end
