LABEL_WIDTH = 20
USER_WIDTH = 50

def print_users(*users)
  puts 'Username: '.ljust(LABEL_WIDTH) + users.map { |u| u.username.to_s.ljust(USER_WIDTH) }.join
  puts 'Email: '.ljust(LABEL_WIDTH) + users.map { |u| u.email.to_s.ljust(USER_WIDTH) }.join
  puts 'Name: '.ljust(LABEL_WIDTH) + users.map { |u| u.full_name.to_s.ljust(USER_WIDTH) }.join
  puts 'Permission: '.ljust(LABEL_WIDTH) + users.map { |u| u.permission.to_s.ljust(USER_WIDTH) }.join

  puts 'Courses: '.ljust(LABEL_WIDTH) + users.map { |u| u.courses.count.to_s.ljust(USER_WIDTH) }.join
  puts 'Submissions: '.ljust(LABEL_WIDTH) + users.map { |u| u.submissions.count.to_s.ljust(USER_WIDTH) }.join
  puts 'Read states: '.ljust(LABEL_WIDTH) + users.map { |u| u.activity_read_states.count.to_s.ljust(USER_WIDTH) }.join
  puts 'Repositories: '.ljust(LABEL_WIDTH) + users.map { |u| u.repositories.count.to_s.ljust(USER_WIDTH) }.join
end

u1_id = ARGV[0].to_i
u2_id = ARGV[1].to_i

u1 = User.find(u1_id)
u2 = User.find(u2_id)

print_users u1, u2

puts ''

c = ''
until %W[\r \n y n f].include? c
  u1, u2 = u2, u1 if c == 's'
  puts "Invalid input #{c}" unless c == 's'
  puts "Are you sure you want to merge #{u1.username} into #{u2.username}? (y)es|(N)o|(f)orce|(s)wap"
  c = $stdin.getch.downcase
end

if %W[\r \n n].include? c
  puts "Merge cancelled"
  return
end

success = u1.merge_into(u2, force: c == 'f')
if success
  puts "Successfully merged #{u1.username} into #{u2.username}"
  print_users u2
else
  puts "Merge failed"
  puts u1.errors.full_messages.join('\n')
end

