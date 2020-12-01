require 'set'

class FeedbackPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.zeus?
        scope.all
      elsif user
        scope.joins(:evaluation_user).where(evaluation_users: { user: user })
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

  def refresh?
    show?
  end

  def complete?
    required_rubrics = record.rubrics.map(&:id).to_set
    found_rubrics = record.scores.map(&:rubric_id).to_set

    # For every template, there should be a score
    required_rubrics.subset?(found_rubrics)
  end

  def permitted_attributes
    attrs = %i[submission_id]
    attrs << :completed if complete?
    attrs
  end

  private

  def course_admin?
    user&.course_admin?(record&.evaluation&.series&.course)
  end
end
