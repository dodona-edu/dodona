class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user && user.admin?
  end

  def show?
    user && (user.admin? || user.id == record.id)
  end

  def new?
    user && user.admin?
  end

  def edit?
    user && (user.zeus? || (user.staff? && !record.zeus?))
  end

  def create?
    user && user.admin?
  end

  def update?
    user && (user.zeus? || (user.staff? && !record.zeus?))
  end

  def destroy?
    user && user.zeus?
  end

  def photo?
    user && user.admin?
  end

  def impersonate?
    return false unless user
    return false if user == record
    return true if user.zeus?
    return true if user.staff? && record.student?
    false
  end

  def stop_impersonating?
    true
  end

  def token_sign_in?
    true
  end

  def permitted_attributes
    if user && user.zeus?
      [:username, :ugent_id, :first_name, :last_name, :email, :permission]
    elsif user && user.staff?
      [:permission]
    else
      []
    end
  end
end
