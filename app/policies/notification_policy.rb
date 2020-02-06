class NotificationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def update?
    record.user == user
  end

  def destroy?
    record.user == user
  end

  def destroy_all?
    user.present?
  end

  def permitted_attributes
    %i[read]
  end
end
