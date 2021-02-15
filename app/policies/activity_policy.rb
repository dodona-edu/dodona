class ActivityPolicy < ApplicationPolicy
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
    return true if user&.admin?
    return false if !user && record.access_private?
    return true if record.ok?
    return false unless user
    return true if record.started_for?(user)

    false
  end

  def description?
    true
  end

  def info?
    return false unless user
    return false if record.removed?
    return true if user.zeus?
    return true if user.repository_admin?(record.repository)
    return true if user.staff? && record&.access_public?

    user.administrating_courses
        .joins(course_repositories: :repository)
        .where(repositories: { id: record.repository.id })
        .any?
  end

  def update?
    return false unless record.ok?

    user&.repository_admin?(record.repository)
  end

  def media?
    return true if user&.admin?
    return true if record.ok?
    return false unless user
    return true if record.started_for?(user)

    false
  end

  def submit?
    return false if record.removed?
    return false if user.blank?
    return true if user.admin?
    return true if record.ok?

    false
  end

  def read?
    return false if record.removed?
    return false if user.blank?
    return true if user.admin?
    return true if record.ok?

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
