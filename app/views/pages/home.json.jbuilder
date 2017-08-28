json.set! :user do
  json.partial! 'users/user', user: current_user if current_user
end
json.motd 'Welcome'
