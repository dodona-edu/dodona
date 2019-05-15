class PagesPolicy < ApplicationPolicy
  def toggle_anonymous_mode?
    user&.zeus?
  end
end

