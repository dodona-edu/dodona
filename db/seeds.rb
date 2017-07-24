# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

zeus = User.create username: 'zeus', first_name: 'Zeus', last_name: 'Kronosson', email: 'zeus@ugent.be', permission: :zeus

staff = User.create username: 'staff', first_name: 'Stijn', last_name: 'Taff', email: 'staff.coppens@ugent.be', permission: :staff

student = User.create username: 'rbmaerte', first_name: 'Rien', last_name: 'Maertens', email: 'rien.maertens@ugent.be', permission: :student

testcourse = Course.create description: 'This is a test course.', name: 'Test Course' , year: '2017-2018'

# Add student to course
student.courses << testcourse

judge = Judge.create name: 'Testjudge', image: 'dodona-anaconda3.dockerfile', remote: 'git@github.ugent.be:dodona/docker-images.git', renderer: FeedbackTableRenderer,
  runner: SubmissionRunner

repo = Repository.create name: 'Testrepo', remote: '../test-exercises', judge: judge





