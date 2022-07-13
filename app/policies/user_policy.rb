class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user&.zeus?
  end

  def available_for_repository?
    user&.admin?
  end

  def show?
    return false if user.blank?
    return true if user.zeus?
    return true if user.id == record.id

    false
  end

  def update?
    show?
  end

  def create?
    user&.zeus?
  end

  def destroy?
    user&.zeus?
  end

  def impersonate?
    return false unless user
    return false if user == record
    return true if user.zeus?

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

  def create_tokens?
    update?
  end

  def list_tokens?
    show?
  end

  def download_submissions?
    show?
  end

  def punchcard?
    show?
  end

  def heatmap?
    show?
  end

  def export?
    return true if zeus?

    record == user
  end

  def permitted_attributes
    if user&.zeus?
      %i[username first_name last_name email permission time_zone]
    else
      %i[time_zone accepted_privacy_policy]
    end
  end
end
