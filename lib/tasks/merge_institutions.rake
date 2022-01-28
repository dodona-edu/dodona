task :merge_institutions, [:arg1, :arg2] => :environment do |task, args|
  i1_id = args[:arg1].to_i
  i2_id = args[:arg2].to_i

  i1 = Institution.find(i1_id)
  i2 = Institution.find(i2_id)

  @output = $stdout
  @input = $stdin

  c = ''
  until %W[\r \n y n].include? c
    i1, i2 = i2, i1 if c == 's'
    @output.puts "Invalid input #{c}" unless ['s', ''].include?(c)
    @output.puts "Are you sure you want to merge #{i1.short_name} into #{i2.short_name}? (y)es|(N)o|(s)wap"
    c = @input.getch.downcase
  end

  if %W[\r \n n].include? c
    @output.puts 'Merge cancelled'
    next
  end

  i1.transaction do
    if (overlap = i1.users.where(username: i2.users.pluck(:username)).count) > 0
      @output.puts "There are #{overlap} overlapping users."
      @output.puts "These users will be merged before the institution can be merged."

      c = ''
      until %W[\r \n y n].include? c
        @output.puts "Invalid input #{c}" unless c.blank?
        @output.puts "Do you want to continue the merge? (y)es|(N)o"
        c = @input.getch.downcase
      end
      next unless c == 'y'

      i1.users.each do |u1|
        u2 = i2.users.find(username: u1.username)
        unless u2.nil?
          print_users u1, u2

          @output.puts ''

          c = ''
          until %W[\r \n y c f].include? c
            u1, u2 = u2, u1 if c == 's'
            @output.puts "Invalid input #{c}" unless ['s', ''].include?(c)
            @output.puts "Are you sure you want to merge #{u1.email} into #{u2.email}? (Y)es|(f)orce|(s)wap|(c)ancel"
            c = @input.getch.downcase
          end

          @output.puts ''

          if c == 'c'
            @output.puts 'Merge cancelled'
            i1.rolledback!
            next
          end

          success = u1.merge_into(u2, force: c == 'f', force_institution_id: i2.id)
          if success
            @output.puts "Successfully merged #{u1.email} into #{u2.email}"
            print_users u2
          else
            @output.puts 'Merge failed'
            @output.puts u1.errors.full_messages.join('\n')
            i1.rolledback!
            next
          end
        end
      end
    end

    success = i1.merge_into(i2)
    if success
      @output.puts "Successfully merged #{i1.short_name} into #{i2.short_name}"
    else
      @output.puts 'Merge failed'
      @output.puts i1.errors.full_messages.join('\n')
      i1.rolledback!
      next
    end
  end
end

LABEL_WIDTH = 20
USER_WIDTH = 50
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
