# This policy contains no query methods, as they are covered by update? on the evaluation policy.
class EvaluationExercisePolicy < ApplicationPolicy
  def permitted_attributes
    %i[visible_score]
  end
end
