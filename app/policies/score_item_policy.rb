# This policy contains no query methods, as they are covered by score_items? on the evaluation policy.
class ScoreItemPolicy < ApplicationPolicy
  def permitted_attributes_for_create
    %i[evaluation_exercise_id maximum name visible description]
  end

  def permitted_attributes_for_update
    %i[maximum name visible description]
  end
end
