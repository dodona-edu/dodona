class PagesPolicy < ApplicationPolicy
  def toggle_demo_mode?
    user&.zeus? || user&.a_course_admin?
  end

  def toggle_dark_mode?
    true
  end

  def profile?
    user.present?
  end
end
