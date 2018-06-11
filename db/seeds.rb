# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Rails.env.development?

  puts 'Creating institution'

  ugent = Institution.create name: 'Universiteit Gent', short_name: 'UGent', logo: 'UGent.png', sso_url: 'https://ugent.be', slo_url: 'https://ugent.be', certificate: 'Test certificate please ignore', entity_id: 'https://ugent.be', provider: :saml


  puts 'Creating users'

  zeus = User.create username: 'zeus', first_name: 'Zeus', last_name: 'Kronosson', email: 'zeus@ugent.be', permission: :zeus, institution: ugent

  staff = User.create username: 'staff', first_name: 'Stijn', last_name: 'Taff', email: 'stijn.taff@ugent.be', permission: :staff, institution: ugent

  jelix = User.create username: 'jvdrfeu', first_name: 'Jelix', last_name: 'Vanderfeught', email: 'jelix.vanderfeught@ugent.be', permission: :student, institution: ugent

  mart = User.create username: 'mbesuere', first_name: 'Mart', last_name: 'Besuere', email: 'mart.besuere@ugent.be', permission: :student, institution: ugent

  student = User.create username: 'rbmaerte', first_name: 'Rien', last_name: 'Maertens', email: 'rien.maertens@ugent.be', permission: :student, institution: ugent

  students = Array.new(500) do
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    username = Faker::Internet.unique.user_name(5..8)
    User.create first_name: first_name,
                last_name: last_name,
                username: username,
                ugent_id: Faker::Number.number(8).to_s,
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

  #  biopythia-judge = Judge.create name: 'biopythia', image: 'dodona-biopythia', remote: 'git@github.ugent.be:dodona/judge-biopythia.git', renderer: PythiaRenderer

  #  prolog-judge = Judge.create name: 'prolog', image: 'dodona-prolog', remote: 'git@github.ugent.be:dodona/judge-prolog.git', renderer: FeedbackTableRenderer, runner: SubmissionRunner
  #  bash-judge = Judge.create name: 'bash', image: 'dodona-bash', remote: 'git@github.ugent.be:dodona/judge-bash.git', renderer: FeedbackTableRenderer, runner: SubmissionRunner
  #  junit-judge = Judge.create name: 'junit', image: 'dodona-java', remote: 'git@github.ugent.be:dodona/judge-junit.git', renderer: FeedbackTableRenderer, runner: SubmissionRunner
  #  javascript-judge = Judge.create name: 'javascript', image: 'dodona-nodejs', remote: 'git@github.ugent.be:dodona/dodona-javascript.git', renderer: FeedbackTableRenderer, runner: SubmissionRunner

  puts 'Create & clone exercise repository'

  exercise_repo = Repository.create name: 'Example Python Exercises', remote: 'git@github.ugent.be:dodona/example-exercises.git', judge: pythia_judge
  exercise_repo.process_exercises

  puts 'Add series and exercises to courses'

  # Add exercices to test course
  courses.each do |course|
    series = []
    series << Series.create(name: 'Verborgen reeks',
                            course: course,
                            visibility: :hidden)
    series << Series.create(name: 'Gesloten reeks',
                            course: course,
                            visibility: :closed)
    20.times do |i|
      s = Series.create(name: "Reeks #{i}",
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
      s.exercises << exercise_repo.exercises
    end
  end

end
