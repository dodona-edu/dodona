json.array! @course_memberships do |cm|
  json.partial! 'course_member_data', locals: { user: cm.user, course_membership: cm }
end
