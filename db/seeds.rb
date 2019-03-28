# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Rails.env.development?

  puts 'Creating institution'

  ugent = Institution.create name: 'Universiteit Gent (login werkt niet in develop)', short_name: 'UGent', logo: 'UGent.png', sso_url: 'https://ugent.be', slo_url: 'https://ugent.be', certificate: 'Test certificate please ignore', entity_id: 'https://ugent.be', provider: :saml

  college_waregem = Institution.create name: 'College Waregem', short_name: 'College Waregem', logo: 'collegewaregem.png', provider: :office365, identifier: '9fdf506a-3be0-4f07-9e03-908ceeae50b4'

  sg_paulus = Institution.create name: 'Scholengroep Paulus', short_name: 'SGPaulus', logo: 'collegewaregem.png', provider: :office365, identifier: 'af15916d-7d77-43f9-b366-ae98d0fe36be'

  slo = Institution.create name: 'SLO Wetenschappen', short_name: 'SLOW', logo: 'ugent.png', provider: :smartschool, identifier: 'https://slow.smartschool.be'

  college_ieper = Institution.create name: 'College Ieper', short_name: 'College Ieper', logo: 'ugent.png', provider: :smartschool, identifier: 'https://college-ieper.smartschool.be'

  sint_bavo = Institution.create(name: 'Sint-Bavo Humaniora Gent', short_name: 'sbhg', logo: 'sbhg.jpeg', provider: 'office365', identifier: 'a1d4c74b-2a28-46a6-89a5-912641f59eae')

  puts 'Creating users'

  zeus = User.create username: 'zeus', first_name: 'Zeus', last_name: 'Kronosson', email: 'zeus@ugent.be', permission: :zeus, institution: nil, token: 'zeus'

  staff = User.create username: 'staff', first_name: 'Stijn', last_name: 'Taff', email: 'stijn.taff@ugent.be', permission: :staff, institution: nil, token: 'staff'

  jelix = User.create username: 'jvdrfeu', first_name: 'Jelix', last_name: 'Vanderfeught', email: 'jelix.vanderfeught@ugent.be', permission: :student, institution: nil, token: 'student'

  mart = User.create username: 'mbesuere', first_name: 'Mart', last_name: 'Besuere', email: 'mart.besuere@ugent.be', permission: :student, institution: ugent

  student = User.create username: 'rbmaerte', first_name: 'Rien', last_name: 'Maertens', email: 'rien.maertens@ugent.be', permission: :student, institution: ugent

  students = Array.new(500) do
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    username = Faker::Internet.unique.user_name(5..8)
    User.create first_name: first_name,
                last_name: last_name,
                username: username,
                email: "#{first_name}.#{last_name}.#{username}@UGent.BE".downcase,
                permission: :student,
                institution: ugent
  end

  puts 'Creating courses'

  courses = []

  courses << Course.create(description: 'This is a test course.', name: 'Open Test Course', year: '2017-2018', registration: 'open', visibility: 'visible', teacher: 'Prof. Gobelijn')
  courses << Course.create(description: 'This is a test course.', name: 'Moderated Test Course', year: '2017-2018', registration: 'moderated', visibility: 'visible', teacher: 'Prof. Barabas')
  courses << Course.create(description: 'This is a test course.', name: 'Hidden Test Course', year: '2017-2018', registration: 'open', visibility: 'hidden', teacher: 'Prof. Kumulus')
  courses << Course.create(description: 'This is a test course.', name: 'Closed Test Course', year: '2017-2018', registration: 'closed', visibility: 'hidden', teacher: 'Graaf van Rommelgem')
  courses << Course.create(description: 'This is a test course.', name: 'Old Open Test Course', year: '2016-2017', registration: 'open', visibility: 'visible', teacher: 'Prof. Gobelijn')
  courses << Course.create(description: 'This is a test course.', name: 'Very Old Open Test Course', year: '2015-2016', registration: 'open', visibility: 'visible', teacher: 'Prof. Gobelijn')

  puts 'Adding users to courses'

  courses.each do |course|
    course.administrating_members << mart
    course.enrolled_members << staff
    course.enrolled_members << zeus
    course.unsubscribed_members << jelix
    course.enrolled_members.concat(students.sample(80))
  end

  courses[0].enrolled_members << student
  courses[1].pending_members << student
  courses[2].enrolled_members << student

  # add some students to the moderated course
  pending = students.sample(60)
  courses[1].pending_members.concat(pending - courses[1].enrolled_members)

  puts 'Create & clone judge'

  pythia_judge = Judge.create name: 'pythia', image: 'dodona-anaconda3', remote: 'git@github.ugent.be:dodona/judge-pythia.git', renderer: PythiaRenderer, runner: SubmissionRunner

  # Other judges

  # biopythia-judge = Judge.create name: 'biopythia', image: 'dodona-biopythia', remote: 'git@github.ugent.be:dodona/judge-biopythia.git', renderer: PythiaRenderer

  # prolog-judge = Judge.create name: 'prolog', image: 'dodona-prolog', remote: 'git@github.ugent.be:dodona/judge-prolog.git', renderer: FeedbackTableRenderer, runner: SubmissionRunner
  # bash-judge = Judge.create name: 'bash', image: 'dodona-bash', remote: 'git@github.ugent.be:dodona/judge-bash.git', renderer: FeedbackTableRenderer, runner: SubmissionRunner
  # junit_judge = Judge.create name: 'junit', image: 'dodona-java', remote: 'git@github.ugent.be:dodona/judge-java.git', renderer: FeedbackTableRenderer, runner: SubmissionRunner
  Judge.create name: 'javascript', image: 'dodona-nodejs', remote: 'git@github.ugent.be:dodona/judge-javascript.git', renderer: FeedbackTableRenderer, runner: SubmissionRunner

  puts 'Create & clone exercise repository'

  exercise_repo = Repository.create name: 'Example Python Exercises', remote: 'git@github.ugent.be:dodona/example-exercises.git', judge: pythia_judge
  exercise_repo.process_exercises

  big_exercise_repo = Repository.create name: 'A lot of python exercises', remote: 'git@github.ugent.be:dodona/example-exercises.git', judge: pythia_judge

  Dir.glob("#{big_exercise_repo.full_path}/*")
      .select {|f| File.directory? f}
      .each do |dir|
    100.times do |i|
      FileUtils.cp_r(dir, dir + i.to_s)
    end
  end
  big_exercise_repo.process_exercises

  exercises_list = Exercise.all.to_a

  puts 'Add series, exercises and submissions to courses'

  # Add exercices to test course
  courses.each do |course|
    series = []
    series << Series.create(name: 'Verborgen reeks',
                            description: Faker::Lorem.paragraph(25),
                            course: course,
                            visibility: :hidden)
    series << Series.create(name: 'Gesloten reeks',
                            description: Faker::Lorem.paragraph(25),
                            course: course,
                            visibility: :closed)
    20.times do |i|
      s = Series.create(name: "Reeks #{i}",
                        description: Faker::Lorem.paragraph(25),
                        course: course)
      if Random.rand < 0.1
        t = if Random.rand < 0.3
              Time.now.advance(days: -1 * Random.rand(5))
            else
              Time.now.advance(days: Random.rand(60))
            end
        s.update(deadline: t)
      end
      series << s
    end

    series.each do |s|
      series_exercises = exercises_list.sample(rand(3) + 2)
      s.exercises << series_exercises
      series_exercises.each do |exercise|
        course.enrolled_members.sample(5).each do |student|
          status = if rand() < 0.5
                     :correct
                   else
                     :wrong
                   end
          Submission.create user: student,
                            course: s.course,
                            exercise: exercise,
                            evaluate: false,
                            skip_rate_limit_check: true,
                            result: {}.to_json,
                            status: status,
                            accepted: status == :correct,
                            code: "print(input())\n"
        end
      end
    end
  end

  puts 'Create Status Test course'

  status_test = Course.create(name: 'Status Test', year: '2018-2019', registration: 'open', visibility: 'visible', teacher: 'Prof. Ir. Dr. Dr. Msc. Bsc.', administrating_members: [zeus])

  deadline = Time.now - 1.day
  after_deadline = deadline + 1.hour
  before_deadline = deadline - 1.hour

  statuses = [:correct, :wrong, :none]
  code = 'print(input())'

  status_exercises = statuses.each_with_index.map do |before, i|
    afters = statuses.each_with_index.map do |after, j|
      exercise = Exercise.offset(statuses.count * i + j).first
      if before != :none
        Submission.create user: zeus,
                          exercise: exercise,
                          evaluate: false,
                          skip_rate_limit_check: true,
                          course: status_test,
                          status: before,
                          accepted: before == :correct,
                          created_at: before_deadline,
                          code: code
      end
      if after != :none
        Submission.create user: zeus,
                          exercise: exercise,
                          evaluate: false,
                          skip_rate_limit_check: true,
                          course: status_test,
                          status: after,
                          accepted: after == :correct,
                          created_at: after_deadline,
                          code: code
      end
      [after, exercise]
    end
    [before, afters.to_h]
  end.to_h

  Series.create name: "Ongebruikte oefeningen",
                course: status_test,
                exercises: [status_exercises[:none][:wrong], status_exercises[:wrong][:none], status_exercises[:wrong][:wrong]]

  Series.create name: "Onbegonnen zonder deadline",
                course: status_test,
                exercises: [status_exercises[:none][:none]]

  Series.create name: "Onbegonnen met deadline",
                course: status_test,
                deadline: deadline,
                exercises: [status_exercises[:none][:none]]

  Series.create name: "Alles correct zonder deadline",
                course: status_test,
                exercises: [status_exercises[:correct][:none]]

  Series.create name: "Alles correct voor deadline",
                course: status_test,
                deadline: deadline,
                exercises: [status_exercises[:correct][:none]]

  Series.create name: "Alles correct voor en na deadline",
                course: status_test,
                deadline: deadline,
                exercises: [status_exercises[:correct][:correct]]

  Series.create name: "Alles correct na deadline",
                course: status_test,
                deadline: deadline,
                exercises: [status_exercises[:none][:correct]]

  Series.create name: "Verkeerd voor, correct na deadline",
                course: status_test,
                deadline: deadline,
                exercises: [status_exercises[:wrong][:correct]]

  Series.create name: "Correct voor, verkeerd na deadline",
                course: status_test,
                deadline: deadline,
                exercises: [status_exercises[:correct][:wrong]]

  Series.create name: "Correcte oplossing bestaat, maar niet laatste, na deadline",
                course: status_test,
                deadline: Time.now,
                exercises: [status_exercises[:correct][:wrong]]

  Series.create name: "Correcte oplossing bestaat, maar niet laatste, zonder deadline",
                course: status_test,
                exercises: [status_exercises[:correct][:wrong]]

  Series.create name: "Begonnen correct",
                course: status_test,
                exercises: [status_exercises[:correct][:none], status_exercises[:none][:none]]

  Series.create name: "Begonnen correct voor deadline",
                course: status_test,
                deadline: deadline,
                exercises: [status_exercises[:correct][:none], status_exercises[:none][:none]]

  Series.create name: "Begonnen correct na deadline",
                course: status_test,
                deadline: deadline,
                exercises: [status_exercises[:none][:correct], status_exercises[:none][:none]]
end
