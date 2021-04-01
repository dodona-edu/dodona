require 'set'

class FeedbackPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.zeus?
        scope.all
      elsif user
        common = scope.joins(:evaluation_user, { evaluation: :series })
        # If the user is the evaluation user and the evaluation has been released
        student = common.where(evaluation_users: { user: user }, evaluation: { released: true })
        # If the user is a staff member for the course of the evaluation
        staff = common.where(evaluation: { series: { course_id: user.administrating_courses.map(&:id) } })
        student.or(staff)
      else
        scope.none
      end
    end
  end

  def show?
    course_admin?
  end

  def update?
    course_admin?
  end

  def permitted_attributes
    attrs = %i[submission_id completed]
    attrs << { scores_attributes: %i[score id score_item_id] }
    attrs
  end

  private

  def course_admin?
    user&.course_admin?(record&.evaluation&.series&.course)
  end
end
