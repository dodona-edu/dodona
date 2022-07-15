# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# separate method as always Submission.create is used instead of a factory
def submission_summary(status)
  return 'All tests succeeded.' if status == :correct
  return "#{Faker::Number.number(digits: 2)} tests failed." if status == :wrong
  nil
end

def academic_year(diff = 0)
  start_year = Date.current.month > 8 ? Date.current.year : Date.current.year - 1
  "#{start_year + diff}-#{start_year + 1 + diff}"
end

def fill_series_with_realistic_submissions(s)
  s.content_pages.each do |content|
    s.course.enrolled_members.sample(rand(45)).each do |student|
      ActivityReadState.create user: student,
                               course: s.course,
                               activity: content
    end
  end

  s.exercises.each_with_index do |exercise, k|
    difficulty = rand(1..(k+1))
    s.course.enrolled_members.sample(rand(3*(6-difficulty)..45)).each do |student|
      # Normally distributed submissions between 8am and 10pm, the day before the deadline, with a peek around 1pm
      submission_time = s.deadline - 1.day + 8.hour + rand(0..420).minutes + rand(0..420).minutes
      # Some users missed the deadline
      submission_time += rand(7).days if rand(10) == 1
      tries = rand(1..(3 * difficulty)) + rand(1..(3 * difficulty))
      tries.times do |j|
        status = if j + rand(7) > tries + difficulty
                   :correct
                 else
                   [ :wrong, :wrong, 'time limit exceeded', 'runtime error', 'compilation error', 'memory limit exceeded', 'output limit exceeded' ][rand(7)]
                 end
        submission_time += rand(30).minutes # submission within 30 minutes after the previous submission
        Submission.create user: student,
                          course: s.course,
                          exercise: exercise,
                          evaluate: false,
                          skip_rate_limit_check: true,
                          status: status,
                          accepted: status == :correct,
                          summary: submission_summary(status),
                          created_at: submission_time,
                          code: "print(input())\n",
                          result: File.read(Rails.root.join('db', 'results', "#{exercise.judge.name}-result.json"))
      end
    end
  end
end

if Rails.env.development?
  start = Time.now


  puts "Creating institutions (#{Time.now - start})"

  ugent = Institution.create name: 'Universiteit Gent (login werkt niet in develop)', short_name: 'UGent', logo: 'UGent.png', category: 1
  artevelde = Institution.create name: 'Artevelde', short_name: 'Artevelde', logo: 'artevelde.png', category: 1
  sg_paulus = Institution.create name: 'Scholengroep Paulus', short_name: 'SGPaulus', logo: 'UGent.png'
  slo = Institution.create name: 'SLO Wetenschappen', short_name: 'SLOW', logo: 'ugent.nl.png'
  college_ieper = Institution.create name: 'College Ieper', short_name: 'College Ieper', logo: 'ugent.nl.png'
  sint_bavo = Institution.create name: 'Sint-Bavo Humaniora Gent', short_name: 'sbhg', logo: 'sbhg.jpeg'
  elixir = Institution.create name: 'Elixir', short_name: 'Elixir', logo: 'elixir.png', category: 2
  vlaanderen = Institution.create name: 'Vlaamse Overheid', short_name: 'Vlaamse Overheid', logo: 'vlaamse-overheid.png', category: 2

  puts "Creating providers (#{Time.now - start})"

  # Office 365.
  Provider::Office365.create institution: artevelde, identifier: 'b6e080ea-adb9-4c79-9303-6dcf826fb854'
  Provider::Office365.create institution: sg_paulus, identifier: 'af15916d-7d77-43f9-b366-ae98d0fe36be'
  Provider::Office365.create institution: sint_bavo, identifier: 'a1d4c74b-2a28-46a6-89a5-912641f59eae'

  # SAML.
  Provider::Saml.create institution: ugent, sso_url: 'https://ugent.be', slo_url: 'https://ugent.be', certificate: 'Test certificate please ignore', entity_id: 'https://identity.ugent.be/simplesaml/saml2/idp/metadata.php'
  Provider::Saml.create institution: elixir, sso_url: 'https://ugent.be', slo_url: 'https://ugent.be', certificate: 'Test certificate please ignore', entity_id: 'https://login.elixir-czech.org/idp/'

  # Smartschool.
  Provider::Smartschool.create institution: slo, identifier: 'https://slow.smartschool.be'
  Provider::Smartschool.create institution: college_ieper, identifier: 'https://college-ieper.smartschool.be'

  # OIDC
  Provider::Oidc.create institution: vlaanderen, client_id: '12345', issuer: 'https://authenticatie.vlaanderen.be/op'

  # Personal providers
  Provider::Office365.create identifier: '9188040d-6c67-4c5b-b112-36a304b66dad', institution: nil
  Provider::GSuite.create identifier: nil, institution: nil

  puts "Creating users (#{Time.now - start})"

  zeus = User.create username: 'zeus', first_name: 'Zeus', last_name: 'Kronosson', email: 'zeus@ugent.be', permission: :zeus, institution: nil, token: 'zeus'

  staff = User.create username: 'staff', first_name: 'Stijn', last_name: 'Taff', email: 'stijn.taff@ugent.be', permission: :staff, institution: nil, token: 'staff'

  jelix = User.create username: 'jvdrfeu', first_name: 'Jelix', last_name: 'Vanderfeught', email: 'jelix.vanderfeught@ugent.be', permission: :student, institution: nil, token: 'student'

  mart = User.create username: 'mbesuere', first_name: 'Mart', last_name: 'Besuere', email: 'mart.besuere@ugent.be', permission: :student, institution: ugent

  student = User.create username: 'rbmaerte', first_name: 'Rien', last_name: 'Maertens', email: 'rien.maertens@ugent.be', permission: :student, institution: ugent

  students = Array.new(250) do
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    username = Faker::Internet.unique.user_name()
    User.create first_name: first_name,
                last_name: last_name,
                username: username,
                email: "#{first_name}.#{last_name}.#{username}@UGent.BE".downcase,
                permission: :student,
                institution: ugent
  end

  overlapping_students_ugent = Array.new(3) do |i|
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    username = "test" + i.to_s
    User.create first_name: first_name,
                last_name: last_name,
                username: username,
                email: "#{first_name}.#{last_name}.#{username}@UGent.BE".downcase,
                permission: :student,
                institution: ugent
  end

  overlapping_students_artevelde = Array.new(3) do |i|
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    username = "test" + i.to_s
    User.create first_name: first_name,
                last_name: last_name,
                username: username,
                email: "#{first_name}.#{last_name}.#{username}@Artevelde.BE".downcase,
                permission: :student,
                institution: artevelde
  end

  unique_students_artevelde = Array.new(50) do
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    username = Faker::Internet.unique.user_name()
    User.create first_name: first_name,
                last_name: last_name,
                username: username,
                email: "#{first_name}.#{last_name}.#{username}@Artevelde.BE".downcase,
                permission: :student,
                institution: artevelde
  end

  students = students + overlapping_students_ugent + overlapping_students_artevelde + unique_students_artevelde

  puts "Creating identities (#{Time.now - start})"

  User.find_each do |user|
    if user.institution.present?
      Identity.create provider: user.institution.providers.first,
                      identifier: user.username,
                      user: user
    end
  end

  puts "Creating API tokens (#{Time.now - start})"

  [zeus, staff, jelix, mart, student].each do |user|
    token = user.token || user.username
    ApiToken.create description: format('Seeded token (= %s)', token),
                    token_digest: ApiToken.digest(token),
                    user: user
  end

  puts "Creating labels (#{Time.now - start})"
  %w[red pink purple deep-purple indigo teal orange brown blue-gray].each do |color|
    Label.create name: Faker::GreekPhilosophers.unique.name, color: color
  end

  puts "Creating programming languages (#{Time.now - start})"
  ICON_MAP = {
    'python' => 'language-python',
    'sh' => 'bash',
    'javascript' => 'language-javascript',
    'bash' => 'bash',
    'java' => 'language-java',
    'prolog' => 'owl',
    'haskell' => 'language-haskell',
    'R' => 'language-r',
    'csharp' => 'language-csharp',
    'text' => nil
  }
  ICON_MAP.each do |language, icon|
    ProgrammingLanguage.create name: language, icon: icon
  end

  puts "Creating courses (#{Time.now - start})"

  courses = []

  courses << Course.create(description: 'This is a test course.', name: 'Open for All Test Course', year: academic_year, registration: 'open_for_all', visibility: 'visible_for_all', moderated: false, teacher: 'Prof. Gobelijn')
  courses << Course.create(description: 'This is a test course.', name: 'Open for Institution Test Course', year: academic_year, registration: 'open_for_institution', visibility: 'visible_for_institution', moderated: false, teacher: 'Prof. Gobelijn', institution: ugent)
  courses << Course.create(description: 'This is a test course.', name: 'Open Moderated Test Course', year: academic_year, registration: 'open_for_all', visibility: 'visible_for_all', moderated: true, teacher: 'Prof. Barabas')
  courses << Course.create(description: 'This is a test course.', name: 'Hidden Test Course', year: academic_year, registration: 'open_for_all', visibility: 'hidden', moderated: false, teacher: 'Prof. Kumulus')
  courses << Course.create(description: 'This is a test course.', name: 'Closed Test Course', year: academic_year, registration: 'closed', visibility: 'hidden', moderated: false, teacher: 'Graaf van Rommelgem')
  courses << Course.create(description: 'This is a test course.', name: 'Old Open for All Test Course', year: academic_year(-1), registration: 'open_for_all', visibility: 'visible_for_all', teacher: 'Prof. Gobelijn')
  courses << Course.create(description: 'This is a test course.', name: 'Very Old Open for All Test Course', year: academic_year(-2), registration: 'open_for_all', visibility: 'visible_for_all', teacher: 'Prof. Gobelijn')
  courses << Course.create(description: 'This is a test course.', name: 'Featured course', year: academic_year(-2), registration: 'open_for_all', visibility: 'visible_for_all', teacher: 'Prof. Zonnebloem', featured: true)

  puts "Adding users to courses (#{Time.now - start})"

  courses.each do |course|
    course.administrating_members << mart
    course.enrolled_members << staff
    course.enrolled_members << zeus
    course.unsubscribed_members << jelix
    course.enrolled_members.concat(students.sample(80))
  end

  courses[0].enrolled_members << student
  courses[1].enrolled_members << student
  courses[2].pending_members << student
  courses[3].enrolled_members << student

  # add some students to the moderated course
  pending = students.sample(60)
  courses[2].pending_members.concat(pending - courses[2].enrolled_members)

  puts "Adding labels to courses (#{Time.now - start})"
  courses.each do |course|
    cl = CourseLabel.create course_id: course.id, name: Faker::CryptoCoin.unique.coin_name, created_at: Time.now, updated_at: Time.now
    course.enrolled_members.sample(2).each do |student|
      CourseMembershipLabel.create course_membership_id: CourseMembership.find_by(course_id: course.id, user_id: student.id).id,
                                   course_label_id: cl.id
    end
  end

  puts "Create & clone judge (#{Time.now - start})"

  if ENV["SKIP_PYTHON_JUDGE"] == 'true'
    python_judge = Judge.create name: 'python', image: 'dodona/dodona-python', remote: 'git@github.com:dodona-edu/judge-java12.git', renderer: PythiaRenderer
  else
    python_judge = Judge.create name: 'python', image: 'dodona/dodona-python', remote: 'git@github.com:dodona-edu/judge-pythia.git', renderer: PythiaRenderer
  end

  raise "Could not initialize python judge, try again or use 'SKIP_PYTHON_JUDGE=true rails db:setup'" if python_judge.nil?

  # Other judges

  # prolog-judge = Judge.create name: 'prolog', image: 'dodona-prolog', remote: 'git@github.com:dodona-edu/judge-prolog.git', renderer: FeedbackTableRenderer
  # bash-judge = Judge.create name: 'bash', image: 'dodona-bash', remote: 'git@github.com:dodona-edu/judge-bash.git', renderer: FeedbackTableRenderer
  # junit_judge = Judge.create name: 'junit', image: 'dodona-java', remote: 'git@github.com:dodona-edu/judge-java.git', renderer: FeedbackTableRenderer
  Judge.create name: 'javascript', image: 'dodona/dodona-nodejs', remote: 'git@github.com:dodona-edu/judge-javascript.git', renderer: FeedbackTableRenderer

  puts "Create & clone activity repository (#{Time.now - start})"
  Delayed::Worker.delay_jobs = ->(job) { 'git' != job.queue }
  activity_repo = Repository.create name: 'Example Python Activities', remote: 'git@github.com:dodona-edu/example-exercises.git', judge: python_judge, allowed_courses: courses
  activity_repo.process_activities

  big_activity_repo = Repository.create name: 'A lot of python activities', remote: 'git@github.com:dodona-edu/example-exercises.git', judge: python_judge, allowed_courses: courses
  Delayed::Worker.delay_jobs = true
  Dir.glob("#{big_activity_repo.full_path}/*")
      .select { |f| File.directory? f }
      .each do |dir|
    5.times do |i|
      FileUtils.cp_r(dir, dir + i.to_s)
    end
  end
  big_activity_repo.process_activities

  RepositoryAdmin.create(repository: activity_repo, user: zeus)
  RepositoryAdmin.create(repository: big_activity_repo, user: zeus)

  contents_list = ContentPage.all.to_a
  exercises_list = Exercise.all.to_a

  puts "Add series, content pages, exercises, read states and submissions to courses (#{Time.now - start})"

  # These callback take a good amount of time and aren't necessary
  ActivityReadState.skip_callback(:save, :after, :invalidate_caches)
  Submission.skip_callback(:save, :after, :update_exercise_status)
  Submission.skip_callback(:save, :after, :invalidate_caches)

  # Add contents and exercises to test course
  courses.each do |course|
    activity_numbers_enabled = Random.rand > 0.5
    series = []
    series << Series.create(name: 'Verborgen reeks',
                            description: Faker::Lorem.paragraph(sentence_count: 25),
                            course: course,
                            visibility: :hidden,
                            activity_numbers_enabled: activity_numbers_enabled)
    series << Series.create(name: 'Gesloten reeks',
                            description: Faker::Lorem.paragraph(sentence_count: 25),
                            course: course,
                            visibility: :closed,
                            activity_numbers_enabled: activity_numbers_enabled)
    2.times do |i|
      s = Series.create(name: "Reeks #{i}",
                        description: Faker::Lorem.paragraph(sentence_count: 25),
                        course: course,
                        activity_numbers_enabled: activity_numbers_enabled)
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
      series_contents = contents_list.sample(rand(3))
      s.content_pages << series_contents
      series_contents.each do |content|
        course.enrolled_members.sample(5).each do |student|
          ActivityReadState.create user: student,
                                   course: s.course,
                                   activity: content
        end
      end

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
                            status: status,
                            accepted: status == :correct,
                            summary: submission_summary(status),
                            code: "print(input())\n",
                            result: File.read(Rails.root.join('db', 'results', "#{exercise.judge.name}-result.json"))
        end
      end
    end
  end

  puts "Create Visualisation Test course (#{Time.now - start})"
  visualisation_test = Course.create(name: 'Visualisation Test', year: academic_year, registration: 'open_for_all', visibility: 'visible_for_all', teacher: 'Stijn Taff', administrating_members: [zeus, staff])
  visualisation_test.enrolled_members.concat(students.sample(50))
  big_activity_repo.allowed_courses << visualisation_test
  activity_repo.allowed_courses << visualisation_test
  courses << visualisation_test

  3.times do |i|
    s = Series.create(name: "Reeks #{i}",
                      description: Faker::Lorem.paragraph(sentence_count: 25),
                      course: visualisation_test,
                      activity_numbers_enabled: true,
                      deadline: Date.current - (i+1).weeks)
    s.content_pages << contents_list.sample(rand(2))
    s.exercises << exercises_list.sample(rand(3) + 2)
    fill_series_with_realistic_submissions(s)
  end

  puts "Create Evaluation (#{Time.now - start})"
  s = Series.create(name: "Evaluation",
                    description: Faker::Lorem.paragraph(sentence_count: 25),
                    course: visualisation_test,
                    activity_numbers_enabled: false,
                    deadline: Date.current)
  s.content_pages << contents_list.sample(1)
  s.exercises << exercises_list.sample(2)
  fill_series_with_realistic_submissions(s)

  e = Evaluation.create(series: s, deadline: s.deadline)
  e.exercises = s.exercises
  e.users = s.course.enrolled_members.sample(25)
  e.save()

  e.evaluation_exercises.each do |ee|
    rand(1..5).times do
      ScoreItem.create(evaluation_exercise: ee,
                       maximum: rand(5),
                       name: Faker::Lorem.word,
                       description: Faker::Lorem.sentence)
    end
    ee.feedbacks.sample(rand(5..25)).each do |f|
      if(f.submission.present?)
        ee.score_items.each do |si|
          Score.create(score_item: si,
                       feedback: f,
                       last_updated_by: zeus,
                       score: rand(si.maximum))
        end
        rand(3).times do
          Annotation.create(line_nr: rand(2) == 1 ? 1 : nil,
                            submission: f.submission,
                            annotation_text: Faker::Lorem.sentence,
                            evaluation: e,
                            user: zeus,
                            course: s.course)
        end
      end
    end
  end

  puts "Add questions (#{Time.now - start})"

  courses.each do |c|
    c.submissions.sample(rand(10)).each do |s|
      question_state = rand(3)
      line_nr = rand(2) == 1 ? 1 : nil
      q = Question.create(line_nr: line_nr,
                        submission: s,
                        annotation_text: Faker::Lorem.sentence,
                        question_state: question_state,
                        user: s.user,
                        course: s.course)

      if(question_state > 0)
        q.update(last_updated_by: c.administrating_members.first)
      end

      if(question_state == 2)
        Annotation.create(line_nr: rand(2) == 1 ? 1 : nil,
                          submission: s,
                          annotation_text: Faker::Lorem.sentence,
                          user: c.administrating_members.first,
                          course: s.course)
      end
    end
  end

  puts "Create Status Test course (#{Time.now - start})"

  status_test = Course.create(name: 'Status Test', year: academic_year(-1), registration: 'open_for_all', visibility: 'visible_for_all', teacher: 'Prof. Ir. Dr. Dr. Msc. Bsc.', administrating_members: [zeus])

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
                          summary: submission_summary(before),
                          accepted: before == :correct,
                          created_at: before_deadline,
                          code: code,
                          result: File.read(Rails.root.join('db', 'results', "#{exercise.judge.name}-result.json"))
      end
      if after != :none
        Submission.create user: zeus,
                          exercise: exercise,
                          evaluate: false,
                          skip_rate_limit_check: true,
                          course: status_test,
                          status: after,
                          summary: submission_summary(after),
                          accepted: after == :correct,
                          created_at: after_deadline,
                          code: code,
                          result: File.read(Rails.root.join('db', 'results', "#{exercise.judge.name}-result.json"))
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

  # Add an empty Submission to the course
  exercise = Exercise.last
  Series.create name: "Lege, foute inzending na deadline",
                course: status_test,
                deadline: deadline,
                exercises: [exercise]
  Submission.create user: zeus,
                    exercise: exercise,
                    evaluate: false,
                    skip_rate_limit_check: true,
                    course: status_test,
                    status: :wrong,
                    summary: submission_summary(:wrong),
                    accepted: false,
                    created_at: after_deadline,
                    code: '',
                    result: File.read(Rails.root.join('db', 'results', "#{exercise.judge.name}-result.json"))

  puts "Add announcements (#{Time.now - start})"

  sign_in_announcement = Announcement.create text_nl: "Log in met [zeus](/users/#{zeus.id}/token/#{zeus.token}), [staff](/users/#{staff.id}/token/#{staff.token}) of [student](/users/#{jelix.id}/token/#{jelix.token})",
                      text_en: "Sign in to [zeus](/users/#{zeus.id}/token/#{zeus.token}), [staff](/users/#{staff.id}/token/#{staff.token}) or [student](/users/#{jelix.id}/token/#{jelix.token})",
                      user_group: :everyone,
                      style: :info
  AnnouncementView.create user:zeus, announcement: sign_in_announcement
  AnnouncementView.create user:staff, announcement: sign_in_announcement
  AnnouncementView.create user:jelix, announcement: sign_in_announcement

  a = Announcement.create text_nl: Faker::Markdown.emphasis,
                      text_en: Faker::Markdown.emphasis,
                      user_group: :all_users,
                      style: :danger,
                      start_delivering_at: 5.weeks.ago,
                      stop_delivering_at: 1.week.ago
  AnnouncementView.create user:zeus, announcement: a

  a = Announcement.create text_nl: Faker::Markdown.emphasis,
                      text_en: Faker::Markdown.emphasis,
                      user_group: :students,
                      style: :primary,
                      start_delivering_at: 1.week.from_now
  AnnouncementView.create user:zeus, announcement: a

  a = Announcement.create text_nl: Faker::Markdown.emphasis,
                      text_en: Faker::Markdown.emphasis,
                      user_group: :staff,
                      institution: ugent,
                      style: :success,
                      start_delivering_at: 5.weeks.ago,
                      stop_delivering_at: 1.week.from_now
  AnnouncementView.create user:zeus, announcement: a

  puts "Add rights requests (#{Time.now - start})"

  ActionMailer::Base.perform_deliveries = false
  students.sample(rand(1..10)).each do |s|
    RightsRequest.create(user: s, context: Faker::Lorem.paragraph(sentence_count: 10))
  end

  puts "Finished! (#{Time.now - start})"
end
