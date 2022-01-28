
task :merge_users, [:arg1, :arg2] => :environment do |task, args|
  u1_id = args[:arg1].to_i
  u2_id = args[:arg2].to_i

  MergeUsers.new.merge_users_interactive u1_id, u2_id
end

class MergeUsers
  LABEL_WIDTH = 20
  USER_WIDTH = 50

  def initialize(input = $stdin, output = $stdout)
    @input = input
    @output = output
  end

  def print_users(*users)
    @output.puts 'Username: '.ljust(LABEL_WIDTH) + users.map { |u| u.username.to_s.ljust(USER_WIDTH) }.join
    @output.puts 'Email: '.ljust(LABEL_WIDTH) + users.map { |u| u.email.to_s.ljust(USER_WIDTH) }.join
    @output.puts 'Name: '.ljust(LABEL_WIDTH) + users.map { |u| u.full_name.to_s.ljust(USER_WIDTH) }.join
    @output.puts 'Permission: '.ljust(LABEL_WIDTH) + users.map { |u| u.permission.to_s.ljust(USER_WIDTH) }.join

    @output.puts 'Courses: '.ljust(LABEL_WIDTH) + users.map { |u| u.courses.count.to_s.ljust(USER_WIDTH) }.join
    @output.puts 'Submissions: '.ljust(LABEL_WIDTH) + users.map { |u| u.submissions.count.to_s.ljust(USER_WIDTH) }.join
    @output.puts 'Read states: '.ljust(LABEL_WIDTH) + users.map { |u| u.activity_read_states.count.to_s.ljust(USER_WIDTH) }.join
    @output.puts 'Repositories: '.ljust(LABEL_WIDTH) + users.map { |u| u.repositories.count.to_s.ljust(USER_WIDTH) }.join
  end

  def merge_users_interactive(u1_id, u2_id)
    u1 = User.find(u1_id)
    u2 = User.find(u2_id)

    print_users u1, u2

    @output.puts ''

    c = ''
    until %W[\r \n y n f].include? c
      u1, u2 = u2, u1 if c == 's'
      @output.puts "Invalid input #{c}" unless ['s', ''].include?(c)
      @output.puts "Are you sure you want to merge #{u1.username} into #{u2.username}? (y)es|(N)o|(f)orce|(s)wap"
      c = @input.getch.downcase
    end

    @output.puts ''

    if %W[\r \n n].include? c
      @output.puts 'Merge cancelled'
      return
    end

    success = u1.merge_into(u2, force: c == 'f')
    if success
      @output.puts "Successfully merged #{u1.username} into #{u2.username}"
      print_users u2
    else
      @output.puts 'Merge failed'
      @output.puts u1.errors.full_messages.join('\n')
    end
  end
end
