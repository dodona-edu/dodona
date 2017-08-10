# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Rails.env == 'development'

  zeus = User.create username: 'zeus', first_name: 'Zeus', last_name: 'Kronosson', email: 'zeus@ugent.be', permission: :zeus

  staff = User.create username: 'staff', first_name: 'Stijn', last_name: 'Taff', email: 'stijn.taff@ugent.be', permission: :staff

  jelix = User.create username: 'jvdrfeu', first_name: 'Jelix', last_name: 'Vanderfeught', email: 'jelix.vanderfeught@ugent.be', permission: :student

  mart = User.create username: 'mbesuere', first_name: 'Mart', last_name: 'Besuere', email: 'mart.besuere@ugent.be', permission: :student

  student = User.create username: 'rbmaerte', first_name: 'Rien', last_name: 'Maertens', email: 'rien.maertens@ugent.be', permission: :student
  
  courses = []

  courses << Course.create(description: 'This is a test course.', name: 'Open Test Course', year: '2017-2018', registration: 'open', visibility: 'visible')
  courses << Course.create(description: 'This is a test course.', name: 'Moderated Test Course', year: '2017-2018', registration: 'moderated', visibility: 'visible')
  courses << Course.create(description: 'This is a test course.', name: 'Hidden Test Course', year: '2017-2018', registration: 'closed', visibility: 'hidden')
  # Add student to course

  courses.each do |course|
    course.administrating_members << staff
    course.administrating_members << mart
    course.unsubscribed_members << jelix
  end

  courses[0].enrolled_members << student
  courses[1].pending_members << student
  courses[2].enrolled_members << student

  pythia_judge = Judge.create name: 'pythia', image: 'dodona-anaconda3', remote: 'git@github.ugent.be:dodona/judge-pythia.git', renderer: PythiaRenderer, runner: SubmissionRunner

# Other judges

#  biopythia-judge = Judge.create name: 'biopythia', image: 'dodona-biopythia', remote: 'git@github.ugent.be:dodona/judge-biopythia.git', renderer: PythiaRenderer

#  prolog-judge = Judge.create name: 'prolog', image: 'dodona-prolog', remote: 'git@github.ugent.be:dodona/judge-prolog.git', renderer: FeedbackTableRenderer, runner: SubmissionRunner
#  bash-judge = Judge.create name: 'bash', image: 'dodona-bash', remote: 'git@github.ugent.be:dodona/judge-bash.git', renderer: FeedbackTableRenderer, runner: SubmissionRunner
#  junit-judge = Judge.create name: 'junit', image: 'dodona-java', remote: 'git@github.ugent.be:dodona/judge-junit.git', renderer: FeedbackTableRenderer, runner: SubmissionRunner
#  javascript-judge = Judge.create name: 'javascript', image: 'dodona-nodejs', remote: 'git@github.ugent.be:dodona/dodona-javascript.git', renderer: FeedbackTableRenderer, runner: SubmissionRunner

  exercise_repo = Repository.create name: 'Example Python Exercises', remote: 'git@github.ugent.be:dodona/example-exercises.git', judge: pythia_judge
  exercise_repo.process_exercises

  # Add exercices to test course
  series1 = Series.create name: 'Reeks 1', course: courses[0]
  series1.exercises << exercise_repo.exercises

end
