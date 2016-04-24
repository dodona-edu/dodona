class SubmissionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user && user.admin?
  end

  def show?
    user && ((user == record.user) || user.admin?)
  end

  def create?
    user
  end

  def permitted_attributes
    [:code, :result, :exercise_id]
  end
end
