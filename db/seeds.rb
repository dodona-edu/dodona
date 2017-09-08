# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Rails.env == 'development'

  puts 'Creating users'

  zeus = User.create username: 'zeus', first_name: 'Zeus', last_name: 'Kronosson', email: 'zeus@ugent.be', permission: :zeus

  staff = User.create username: 'staff', first_name: 'Stijn', last_name: 'Taff', email: 'stijn.taff@ugent.be', permission: :staff

  jelix = User.create username: 'jvdrfeu', first_name: 'Jelix', last_name: 'Vanderfeught', email: 'jelix.vanderfeught@ugent.be', permission: :student

  mart = User.create username: 'mbesuere', first_name: 'Mart', last_name: 'Besuere', email: 'mart.besuere@ugent.be', permission: :student

  student = User.create username: 'rbmaerte', first_name: 'Rien', last_name: 'Maertens', email: 'rien.maertens@ugent.be', permission: :student

  students = Array.new(500) do
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    User.create first_name: first_name,
                last_name: last_name,
                username: Faker::Internet.unique.user_name(5..8),
                ugent_id: Faker::Number.number(8).to_s,
                email: "#{first_name}.#{last_name}@ugent.be",
                permission: :student
  end

  puts 'Creating courses'

  courses = []

  courses << Course.create(description: 'This is a test course.', name: 'Open Test Course', year: '2017-2018', registration: 'open', visibility: 'visible')
  courses << Course.create(description: 'This is a test course.', name: 'Moderated Test Course', year: '2017-2018', registration: 'moderated', visibility: 'visible')
  courses << Course.create(description: 'This is a test course.', name: 'Hidden Test Course', year: '2017-2018', registration: 'open', visibility: 'hidden')
  courses << Course.create(description: 'This is a test course.', name: 'Closed Test Course', year: '2017-2018', registration: 'closed', visibility: 'hidden')

  puts 'Adding users to courses'

  courses.each do |course|
    course.administrating_members << mart
    course.enrolled_members << staff
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
      series << Series.create(name: "Reeks #{i}",
                              course: course)
    end

    series.each do |s|
      s.exercises << exercise_repo.exercises
    end
  end

end
