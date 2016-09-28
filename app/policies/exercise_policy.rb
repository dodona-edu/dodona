class ExercisePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.where(visibility: :open).where(status: :ok)
      end
    end
  end

  def index?
    true
  end

  def show?
    return true  if user&.admin?
    return false if record.closed?
    return true  if record.ok?
    return false unless user
    return true  if record.number_of_submissions_for(user).nonzero?
    false
  end

  def edit?
    user&.admin?
  end

  def update?
    user&.admin?
  end

  def users?
    user&.admin?
  end

  def media?
    show?
  end

  def submit?
    return true  if user&.admin?
    return false if record.closed?
    return true  if record.ok?
    false
  end

  def permitted_attributes
    if user&.admin?
      [:visibility, :name_nl, :name_en]
    else
      []
    end
  end
end
