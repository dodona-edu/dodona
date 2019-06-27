class PagesPolicy < ApplicationPolicy
  def toggle_demo_mode?
    user&.zeus?
  end

  def toggle_dark_mode?
    true
  end
end

