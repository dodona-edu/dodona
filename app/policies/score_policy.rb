class ScorePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.zeus?
        scope.all
      elsif user
        common = scope.joins(:score_item, feedback: [:evaluation_user, { evaluation: :series }])
        # Students - visible if own score, if score item is visible and if evaluation is released.
        students = common.where(feedbacks: { evaluations: { released: true }, evaluation_users: { user: user } }, score_items: { visible: true })
        # Staff - visible if course administrator
        staff = common.where(feedbacks: { evaluation: { series: { course_id: user.administrating_courses.map(&:id) } } })

        students.or(staff)
      else
        scope.none
      end
    end
  end

  def create?
    course_admin?
  end

  def update?
    # The check against the expected score is to detect conflicts
    course_admin? && record.expected_score == record.score
  end

  def destroy?
    # The check against the expected score is to detect conflicts
    course_admin? && record.expected_score == record.score
  end

  def permitted_attributes_for_create
    %i[score feedback_id score_item_id]
  end

  def permitted_attributes_for_update
    %i[score expected_score]
  end

  private

  def course_admin?
    course = record&.feedback&.evaluation&.series&.course
    user&.course_admin?(course)
  end
end
