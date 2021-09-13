json.extract! user,
              :id,
              :username,
              :first_name,
              :last_name,
              :email
json.status course_membership.status
json.labels course_membership.course_labels, :name
json.url course_member_url(course_membership.course, user, format: :json)
