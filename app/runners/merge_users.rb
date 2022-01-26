LABEL_WIDTH = 20
USER_WIDTH = 50

u1_id = ARGV[0].to_i
u2_id = ARGV[1].to_i

u1 = User.find(u1_id)
u2 = User.find(u2_id)

puts 'Username: '.ljust(LABEL_WIDTH) + u1.username.to_s.ljust(USER_WIDTH) + u2.username
puts 'Email: '.ljust(LABEL_WIDTH) + u1.email.to_s.ljust(USER_WIDTH) + u2.email
puts 'Name: '.ljust(LABEL_WIDTH) + u1.full_name.to_s.ljust(USER_WIDTH) + u2.full_name
puts 'Permission: '.ljust(LABEL_WIDTH) + u1.permission.to_s.ljust(USER_WIDTH) + u2.permission.to_s

puts 'Courses: '.ljust(LABEL_WIDTH) + u1.courses.count.to_s.ljust(USER_WIDTH) + u2.courses.count.to_s
puts 'Submissions: '.ljust(LABEL_WIDTH) + u1.submissions.count.to_s.ljust(USER_WIDTH) + u2.submissions.count.to_s
puts 'Read states: '.ljust(LABEL_WIDTH) + u1.activity_read_states.count.to_s.ljust(USER_WIDTH) + u2.activity_read_states.count.to_s
puts 'Repositories: '.ljust(LABEL_WIDTH) + u1.repositories.count.to_s.ljust(USER_WIDTH) + u2.repositories.count.to_s

puts ''
puts "Are you sure you want to merge #{u1.username} into #{u2.username}? (y)es|(N)o|(f)orce"
until %W[\r \n y n f].include?((c = $stdin.getch.downcase))
  puts "Invalid input #{c}"
  puts "Are you sure you want to merge #{u1.username} into #{u2.username}? (y)es|(N)o|(f)orce"
end

case c
when 'y'
  success = u1.merge_into(u2)
  puts u1.errors.full_messages.join('\n') unless success
  puts "Successfully merged #{u1.username} into #{u2.username}" if success
when 'f'
  success = u1.merge_into(u2, force: true)
  puts u1.errors.full_messages.join('\n') unless success
  puts "Successfully merged #{u1.username} into #{u2.username}" if success
else
  puts "Merge cancelled"
end
