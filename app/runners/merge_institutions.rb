class MergeInstitutions
  LABEL_WIDTH = 20
  INSTITUTION_WIDTH = 50

  def initialize(input = $stdin, output = $stdout)
    @input = input
    @output = output
  end

  def print_institutions(*institutions)
    @output.puts 'Short name: '.ljust(LABEL_WIDTH) + institutions.map { |i| i.short_name.to_s.ljust(INSTITUTION_WIDTH) }.join
    @output.puts 'Name: '.ljust(LABEL_WIDTH) + institutions.map { |i| i.name.to_s.ljust(INSTITUTION_WIDTH) }.join

    @output.puts 'Courses: '.ljust(LABEL_WIDTH) + institutions.map { |i| i.courses.count.to_s.ljust(INSTITUTION_WIDTH) }.join
    @output.puts 'Users: '.ljust(LABEL_WIDTH) + institutions.map { |i| i.users.count.to_s.ljust(INSTITUTION_WIDTH) }.join
    @output.puts 'Providers: '.ljust(LABEL_WIDTH) + institutions.map { |i| i.providers.count.to_s.ljust(INSTITUTION_WIDTH) }.join
  end

  def merge_institutions_interactive(i1_id, i2_id)
    i1 = Institution.find(i1_id)
    i2 = Institution.find(i2_id)

    print_institutions i1, i2

    c = ''
    until %W[\r \n y n].include? c
      i1, i2 = i2, i1 if c == 's'
      @output.puts "Invalid input #{c}" unless ['s', ''].include?(c)
      @output.puts "Are you sure you want to merge #{i1.short_name} into #{i2.short_name}? (y)es|(N)o|(s)wap"
      c = @input.getch.downcase
    end

    if %W[\r \n n].include? c
      @output.puts 'Merge cancelled'
      return
    end

    i1.transaction do
      if (overlap = i1.users.where(username: i2.users.pluck(:username)).count) > 0
        @output.puts "There are #{overlap} overlapping users."
        @output.puts 'These users will be merged before the institution can be merged.'

        c = ''
        until %W[\r \n y n].include? c
          @output.puts "Invalid input #{c}" if c.present?
          @output.puts 'Do you want to continue the merge? (y)es|(N)o'
          c = @input.getch.downcase
        end
        return unless c == 'y'

        i1.users.where(username: i2.users.pluck(:username)).each do |u1|
          u2 = i2.users.find { |u| u.username == u1.username }
          next if u2.nil?

          @output.puts ''
          success = MergeUsers.new(@input, @output).merge_users_interactive(u1.id, u2.id, force_institution: true)
          raise ActiveRecord::Rollback unless success
        end
      end

      success = i1.merge_into(i2)
      if success
        @output.puts "Successfully merged #{i1.short_name} into #{i2.short_name}"
        print_institutions i2
      else
        @output.puts 'Merge failed'
        @output.puts i1.errors.full_messages.join('\n')
        raise ActiveRecord::Rollback
      end
      success
    end
  end
end
