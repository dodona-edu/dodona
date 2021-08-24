json.extract! @user,
              :id,
              :username,
              :first_name,
              :last_name,
              :email
json.status @course_membership.status
json.labels @users_lables[@user], :name
