# This policy contains few query methods, as they are covered by update? on the evaluation policy.
class EvaluationExercisePolicy < ApplicationPolicy
  def show_total?
    return true if course_admin?

    record.visible_score? && record.evaluation.released?
  end

  def permitted_attributes
    %i[visible_score]
  end

  private

  def course_admin?
    course = record&.evaluation&.series&.course
    user&.course_admin?(course)
  end
end
