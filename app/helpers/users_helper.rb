module UsersHelper
  def editable_permissions
    perms = User.permissions.clone
    perms.delete('zeus') if current_user.teacher?
    perms
  end

  def can_edit_permissions?(user)
    return true if current_user.zeus?
    return false if current_user.student?
    user.student? || user.teacher?
  end
end
