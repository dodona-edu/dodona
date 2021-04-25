module UsersHelper
  def user_page_navigation_links(users, opts, action = 'index')
    opts ||= {}
    controller = 'users' if users.try(:total_pages)
    page_navigation_links users, true, controller, opts, action
  end
end
