class AnnouncementPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.zeus?
        scope
      elsif user.present?
        all_scopes = scope.where(institution_id: user.institution_id).or(scope.where(institution_id: nil))
        @scope = all_scopes.where(user_group: :all_users)
        @scope = scope.or(all_scopes.where(user_group: :students)) if user.student?
        @scope = scope.or(all_scopes.where(user_group: :staff)) if user.staff?
        scope.is_active
      else
        scope.none
      end
    end
  end

  def index?
    user.present?
  end

  def mark_as_read?
    user.present?
  end

  def new?
    user&.zeus?
  end

  def create?
    user&.zeus?
  end

  def destroy?
    user&.zeus?
  end

  def permitted_attributes
    if user&.zeus?
      %i[text start_delivering_at stop_delivering_at user_group institution_id style]
    else
      []
    end
  end
end
