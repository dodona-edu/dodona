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

  def complete?
    required_score_items = record.score_items.map(&:id).to_set
    found_score_items = record.scores.map(&:score_item_id).to_set

    # For every template, there should be a score
    required_score_items == found_score_items
  end

  def permitted_attributes
    attrs = %i[submission_id]
    attrs << :completed if complete?
    attrs << { scores_attributes: %i[score id score_item_id] }
    attrs
  end

  private

  def course_admin?
    user&.course_admin?(record&.evaluation&.series&.course)
  end
end
