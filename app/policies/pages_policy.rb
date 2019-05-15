class PagesPolicy < ApplicationPolicy
  def toggle_demo_mode?
    user&.zeus?
  end
end

