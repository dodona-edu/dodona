class ExercisePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.zeus?
        scope.all
      else
        scope.where(access: :public, status: :ok).or(scope.where(repository: user&.repositories))
      end
    end
  end

  def index?
    true
  end

  def show?
    return true  if user&.admin?
    return true  if record.ok?
    return false unless user
    return true  if record.number_of_submissions_for(user).nonzero?
    false
  end

  def update?
    user&.repository_admin?(record.repository)
  end

  def media?
    show?
  end

  def submit?
    return true  if user&.admin?
    return true  if record.ok?
    false
  end

  def permitted_attributes
    if update?
      %i[access name_nl name_en]
    else
      []
    end
  end
end
