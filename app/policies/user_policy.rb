class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user&.admin?
  end

  def show?
    user && (user.admin? || user.id == record.id)
  end

  def update?
    return false unless user
    return true if user == record
    return true if user.zeus?
    return true if user.staff? && !record.zeus?
    false
  end

  def create?
    user&.admin?
  end

  def destroy?
    user&.zeus?
  end

  def photo?
    user&.admin?
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

  def server_access?
    user&.zeus?
  end

  def courses?
    show?
  end

  def permitted_attributes
    if user&.admin?
      %i[username ugent_id first_name last_name email permission time_zone]
    else
      %i[time_zone]
    end
  end
end
