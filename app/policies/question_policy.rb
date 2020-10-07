class QuestionPolicy < AnnotationPolicy
  def create?
    # If there is no course, don't allow questions.
    return false if record.submission.course.nil?
    return false unless record.submission.course.enabled_questions?

    # Only the submitter (ie. the student) may create questions.
    record.submission.user == user
  end

  def transition?(to, from = nil)
    # Check if the expected state is the same as the actual state.
    return false if from.present? && record.question_state.to_s != from.to_s
    # Don't allow transition if already in the requested state
    return false if record.question_state.to_s == to.to_s
    # Only the course admins can transition, except for the answered state.
    return true if to.to_s == 'answered' && record.user == user

    user.course_admin?(record.submission.course)
  end

  def update?
    # If we are updating the state, authorize the state.
    return transition?(record.transition_to, record.transition_from) if transitioning?

    # Otherwise, we are updating the text of the annotation.
    # Only allow if the question was not answered yet.
    return false unless record.unanswered?

    record.user == user
  end

  def destroy?
    # Don't allow removing if the question was answered.
    return false if record.answered?

    record.user == user
  end

  def permitted_attributes_for_update
    if transitioning?
      %i[question_state]
    else
      super
    end
  end

  private

  def transitioning?
    record.transition_to.present?
  end
end
