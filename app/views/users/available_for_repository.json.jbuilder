json.array! @users do |user|
  json.extract! user, %i[id permission first_name last_name]
  json.institution user.institution.name
end
