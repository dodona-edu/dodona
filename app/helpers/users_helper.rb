module UsersHelper
  def editable_permissions
    perms = User.permissions.to_h
    perms.delete('zeus') if current_user.staff?
    perms
  end

  def can_edit_permissions?(user)
    return true if current_user.zeus?
    return false if current_user.student?

    user.student? || user.staff?
  end

  def user_page_navigation_links(users, opts, action = 'index')
    opts ||= {}
    controller = 'users' if users.try(:total_pages)
    page_navigation_links users, true, controller, opts, action
  end
end
