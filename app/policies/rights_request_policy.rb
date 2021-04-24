class RightsRequestPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user&.zeus?
  end

  def show?
    user&.zeus?
  end

  def create?
    user&.student? && user.rights_request.nil?
  end

  def approve?
    user&.zeus?
  end

  def reject?
    approve?
  end

  def permitted_attributes
    %i[institution_name context]
  end
end
