# This policy contains no query methods, as they are covered by score_items? on the evaluation policy.
class ScoreItemPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.zeus?
        scope.all
      elsif user
        common = scope.joins(evaluation_exercise: { evaluation: :series })
        # Students - visible if score item is visible and if evaluation is released.
        students = common.where(visible: true, evaluation_exercises: { evaluations: { released: true } })
        # Staff - visible if course administrator
        staff = common.where(evaluation_exercise: { evaluation: { series: { course_id: user.administrating_courses.map(&:id) } } })

        students.or(staff)
      else
        scope.none
      end
    end
  end

  def permitted_attributes_for_create
    %i[evaluation_exercise_id maximum name visible description]
  end

  def permitted_attributes_for_update
    %i[maximum name visible description]
  end
end
