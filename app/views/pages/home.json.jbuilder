json.set! :you do
  json.partial! 'users/user', user: current_user if current_user
end
json.motd 'Welcome'
