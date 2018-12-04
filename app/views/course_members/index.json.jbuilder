json.array! @course_memberships do |cm|
  json.extract! cm.user, :id, :username, :permission, :first_name, :last_name, :email
  json.url course_member_url(cm.course, cm.user, format: :json)
end
