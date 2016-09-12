class ExercisePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user && user.admin?
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
    return true  if user && user.admin?
    return false if record.closed?
    return true  if record.ok?
    return false unless user
    return true  if record.number_of_submissions_for(user).nonzero?
    false
  end

  def show_hidden_without_token?
    show? && user && user.admin?
  end

  def edit?
    user && user.admin?
  end

  def update?
    user && user.admin?
  end

  def users?
    user && user.admin?
  end

  def media?
    show?
  end

  def submit?
    return true  if user && user.admin?
    return false if record.closed?
    return true  if record.ok?
    false
  end

  def permitted_attributes
    if user && user.admin?
      [:visibility, :name_nl, :name_en]
    else
      []
    end
  end
end
