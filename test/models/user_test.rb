# == Schema Information
#
# Table name: users
#
#  id             :integer          not null, primary key
#  username       :string(255)
#  first_name     :string(255)
#  last_name      :string(255)
#  email          :string(255)
#  permission     :integer          default("student")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  lang           :string(255)      default("nl")
#  token          :string(255)
#  time_zone      :string(255)      default("Brussels")
#  institution_id :bigint
#  search         :string(4096)
#  seen_at        :datetime
#  sign_in_at     :datetime
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'factory should create user' do
    assert_not_nil create(:user)
  end

  test 'user with emoji in username' do
    name = '🕴'
    user = create :user, username: name
    assert_not_nil user
    assert_equal user.username, name
  end

  test 'user without username should have token' do
    user = create :user, institution: nil
    assert_not_nil user.token
  end

  test 'user with username should not have a token' do
    user = create :user, :with_institution
    assert_nil user.token
  end

  test 'user timezone should be set' do
    user_brussels = create :user
    assert_equal user_brussels.time_zone, 'Brussels'

    user_korea = create :user, email: 'hupseflupse@ghent.ac.kr'
    assert_equal user_korea.time_zone, 'Seoul'
  end

  test 'only zeus and staff should be admin' do
    assert users(:zeus).admin?
    assert users(:staff).admin?
    assert_not users(:student).admin?
  end

  test 'only zeus should always be course admin' do
    assert users(:zeus).course_admin? nil
    assert_not users(:staff).course_admin? nil
    assert_not users(:student).course_admin? nil
  end

  test 'user and staff can be course admin' do
    user = users(:student)
    staff = users(:staff)
    zeus = users(:zeus)

    course = courses(:course1)

    assert_not user.course_admin?(course)
    assert_not staff.course_admin?(course)
    assert zeus.course_admin?(course)

    course.users.push(user, staff, zeus)

    assert_not user.course_admin?(course)
    assert_not staff.course_admin?(course)
    assert zeus.course_admin?(course)

    user.course_memberships.first.update(status: 'course_admin')
    staff.course_memberships.first.update(status: 'course_admin')
    zeus.course_memberships.first.update(status: 'course_admin')

    assert user.administrating_courses.include?(course)
    assert staff.administrating_courses.include?(course)
    assert zeus.administrating_courses.include?(course)
  end

  test 'full name should be n/a when blank' do
    user = build(:user, first_name: nil, last_name: nil)
    assert_equal 'n/a', user.full_name

    user.first_name = ' '
    assert_equal 'n/a', user.full_name

    user.last_name = "\t"
    assert_equal 'n/a', user.full_name

    user.first_name = 'herp'
    user.last_name = 'derp'
    assert_equal 'herp derp', user.full_name
  end

  test 'short name should not be nil' do
    user = build(:user)
    assert_equal user.username, user.short_name

    user.username = nil
    assert_equal user.first_name, user.short_name

    user.first_name = nil
    assert_equal " #{user.last_name}", user.short_name

    user.last_name = nil
    assert_equal 'n/a', user.short_name
  end

  test 'user member_off should tell whether he is in a course or not' do
    user1 = users(:student)
    user2 = users(:staff)

    course1 = build(:course)
    course2 = build(:course)

    user1.courses << course1
    user2.courses << course2

    assert user1.member_of? course1
    assert user2.member_of? course2
    assert_not user1.member_of? course2
    assert_not user2.member_of? course1
  end

  def assert_user_exercises(user, attempted, correct, unfinished)
    assert_equal attempted, user.attempted_exercises, 'wrong amount of attempted exercises'
    assert_equal correct, user.correct_exercises, 'wrong amount of correct exercises'
    assert_equal unfinished, user.unfinished_exercises, 'wrong amount of unfinished exercises'
  end

  test 'user should have correct number of attempted, unfinished and correct exercises' do
    user = users(:student)
    exercise1 = create :exercise
    exercise2 = create :exercise
    exercise3 = create :exercise

    assert_user_exercises user, 0, 0, 0

    create :wrong_submission, user: user, exercise: exercise1
    create :wrong_submission, user: user, exercise: exercise1
    create :wrong_submission, user: user, exercise: exercise1
    assert_user_exercises user, 1, 0, 1

    create :correct_submission, user: user, exercise: exercise1
    create :correct_submission, user: user, exercise: exercise1
    assert_user_exercises user, 1, 1, 0

    create :correct_submission, user: user, exercise: exercise2
    assert_user_exercises user, 2, 2, 0

    create :wrong_submission, user: user, exercise: exercise3
    assert_user_exercises user, 3, 2, 1

    create :submission, user: user, exercise: exercise3
    assert_user_exercises user, 3, 2, 1
  end

  test 'only lti and smartschool users can have blank email' do
    # Validate that lti and smartschool institutions are valid.
    %i[lti_provider smartschool_provider].each do |provider_name|
      provider = create provider_name
      user = build :user, institution: provider.institution
      user.email = nil
      assert user.valid?
    end

    # Validate that every other institution is invalid.
    (AUTH_PROVIDERS - %i[lti_provider smartschool_provider]).each do |provider_name|
      provider = create provider_name
      user = build :user, institution: provider.institution
      user.email = nil
      assert_not user.valid?
    end
  end

  def oauth_hash_for(user)
    oauth_hash = mock
    info_hash = mock
    info_hash.stubs(:email).returns('')
    info_hash.stubs(:first_name).returns(user.first_name)
    info_hash.stubs(:last_name).returns(user.last_name)
    oauth_hash.stubs(:info).returns(info_hash)
    oauth_hash.stubs(:uid).returns(user.username)
    oauth_hash
  end

  # REGRESSION: bug where a smartschool user's update_from_oauth would set
  # their email to an empty string, which would create a RecordNotUnique exception
  test 'two smartschool users without empty string email' do
    smartschool = create :smartschool_provider

    first = build :user, institution: smartschool.institution
    first.email = ''
    assert first.save

    second = build :user, institution: smartschool.institution
    second.email = ''
    assert second.save

    assert first.update_from_provider(oauth_hash_for(first), smartschool).valid?
    assert second.update_from_provider(oauth_hash_for(second), smartschool).valid?
  end

  test 'should transform empty username into nil' do
    saml = create :institution

    user = create :user, institution: saml
    user.update(username: '')

    assert_nil user.username
  end

  test 'should allow two users with empty usernames' do
    user1 = users(:student)
    user2 = users(:staff)

    assert user1.update(username: '')
    assert user2.update(username: '')
  end

  test 'full_name should return a full name that is not equal to actual full name of the user when in demo mode' do
    user = users(:student)
    full_name = user.full_name
    Current.any_instance.stubs(:demo_mode).returns(true)
    assert_not_equal full_name, user.full_name
  end

  test 'first_name should return a first_name that is not equal to actual first name of the user when in demo mode' do
    user = users(:student)
    first_name = user.first_name
    Current.any_instance.stubs(:demo_mode).returns(true)
    assert_not_equal first_name, user.first_name
  end

  test 'last_name should return a last name that is not equal to actual last name of the user when in demo mode' do
    user = users(:student)
    last_name = user.last_name
    Current.any_instance.stubs(:demo_mode).returns(true)
    assert_not_equal last_name, user.last_name
  end

  test 'email should return a email that is not equal to actual email of the user when in demo mode' do
    user = users(:student)
    email = user.email
    Current.any_instance.stubs(:demo_mode).returns(true)
    assert_not_equal email, user.email
  end

  test 'username should return a username that is not equal to actual username of the user when in demo mode' do
    user = users(:student)
    username = user.username
    Current.any_instance.stubs(:demo_mode).returns(true)
    assert_not_equal username, user.username
  end

  test 'institution name should return a name that is not equal to actual institution name of the user when in demo mode' do
    user = create :user, :with_institution
    institution_name = user.institution&.name
    Current.any_instance.stubs(:demo_mode).returns(true)
    assert_not_equal institution_name, user.institution&.name
  end

  test 'recent_exercises should return the 3 most recent exercises submissions have been submitted' do
    user = users(:student)
    exercises = (0..5).map { create :exercise }
    create :series, exercises: exercises
    exercises.each { |e| create :submission, user: user, exercise: e }
    exercises.take(3).each { |e| create :submission, user: user, exercise: e }
    assert_equal exercises.take(3).reverse, user.recent_exercises
  end

  test 'pending_series should return all series of the users courses that have a deadline' do
    user = users(:student)
    course = create :course, users: [user]
    create :series, course: course, activity_count: 2, deadline: 2.minutes.ago # Not pending series
    pending_series = create :series, course: course, activity_count: 2, deadline: 2.minutes.from_now
    assert_equal [pending_series], user.pending_series
  end

  test 'split_last_name should split the "De Achternaam"' do
    user = create :user, last_name: 'De Achternaam', first_name: ''
    assert_equal 'De', user.first_name
    assert_equal 'Achternaam', user.last_name
  end

  test 'split_last_name should not split the "Achternaam"' do
    user = create :user, last_name: 'Achternaam', first_name: 'Voornaam'
    assert_equal 'Voornaam', user.first_name
    assert_equal 'Achternaam', user.last_name
  end

  test 'should be able to order by status in course and name' do
    c = create :course
    u5 = create :user, permission: :student, last_name: 'Adams', first_name: 'Brecht'
    CourseMembership.create user: u5, course: c, status: 'student'
    u2 = create :user, permission: :zeus, last_name: 'Paters', first_name: 'Thomas'
    CourseMembership.create user: u2, course: c, status: 'student'
    u7 = create :user, permission: :zeus, last_name: 'Adams', first_name: 'Amber'
    CourseMembership.create user: u7, course: c, status: 'unsubscribed'
    u1 = create :user, permission: :staff, last_name: 'Pieters', first_name: 'Thomas'
    CourseMembership.create user: u1, course: c, status: 'course_admin'
    u3 = create :user, permission: :staff, last_name: 'Pieters', first_name: 'Jan'
    CourseMembership.create user: u3, course: c, status: 'student'
    u6 = create :user, permission: :student, last_name: 'Boeien', first_name: 'Frank'
    CourseMembership.create user: u6, course: c, status: 'student'
    u4 = create :user, permission: :student, last_name: 'Adams', first_name: 'Anke'
    CourseMembership.create user: u4, course: c, status: 'student'

    assert_equal [u5.id, u2.id, u7.id, u1.id, u3.id, u6.id, u4.id], User.in_course(c).pluck(:id)
    assert_equal [u1.id, u2.id, u3.id, u4.id, u5.id, u6.id, u7.id], User.in_course(c).order_by_status_in_course_and_name('ASC').pluck(:id)
    assert_equal [u7.id, u6.id, u5.id, u4.id, u3.id, u2.id, u1.id], User.in_course(c).order_by_status_in_course_and_name('DESC').pluck(:id)
  end

  test 'should be able to order by exercise submission status in series' do
    c = create :course
    s = create :series, course: c
    e = create :exercise
    SeriesMembership.create series: s, activity: e
    u1 = create :user
    CourseMembership.create user: u1, course: c, status: 'student'
    u2 = create :user
    CourseMembership.create user: u2, course: c, status: 'student'
    create :correct_submission, user: u2, course: c, exercise: e
    u3 = create :user
    CourseMembership.create user: u3, course: c, status: 'student'
    create :correct_submission, user: u3, course: c, exercise: e
    create :wrong_submission, user: u3, course: c, exercise: e

    assert_equal [u1.id, u2.id, u3.id], User.in_course(c).order_by_exercise_submission_status_in_series('ASC', e, s).pluck(:id)
    assert_equal [u3.id, u2.id, u1.id], User.in_course(c).order_by_exercise_submission_status_in_series('DESC', e, s).pluck(:id)
  end

  test 'should be able to order by solved exercises in series' do
    c = create :course
    s = create :series, course: c
    e1 = create :exercise
    e2 = create :exercise
    SeriesMembership.create series: s, activity: e1
    SeriesMembership.create series: s, activity: e2
    u1 = create :user
    CourseMembership.create user: u1, course: c, status: 'student'
    u2 = create :user
    CourseMembership.create user: u2, course: c, status: 'student'
    create :correct_submission, user: u2, course: c, exercise: e1
    create :correct_submission, user: u2, course: c, exercise: e2
    create :wrong_submission, user: u2, course: c, exercise: e2
    u3 = create :user
    CourseMembership.create user: u3, course: c, status: 'student'
    create :wrong_submission, user: u3, course: c, exercise: e1
    create :correct_submission, user: u3, course: c, exercise: e1
    create :correct_submission, user: u3, course: c, exercise: e2

    assert_equal [u1.id, u2.id, u3.id], User.in_course(c).order_by_solved_exercises_in_series('ASC', s).pluck(:id)
    assert_equal [u3.id, u2.id, u1.id], User.in_course(c).order_by_solved_exercises_in_series('DESC', s).pluck(:id)
  end

  test 'should be able to order by solved exercises in course' do
    c = create :course
    s1 = create :series, course: c
    s2 = create :series, course: c
    e1 = create :exercise
    e2 = create :exercise
    a1 = create :content_page
    a2 = create :content_page
    SeriesMembership.create series: s1, activity: e1
    SeriesMembership.create series: s2, activity: e1
    SeriesMembership.create series: s2, activity: e2
    SeriesMembership.create series: s1, activity: a1
    SeriesMembership.create series: s2, activity: a2
    u1 = create :user
    CourseMembership.create user: u1, course: c, status: 'student'
    u2 = create :user
    CourseMembership.create user: u2, course: c, status: 'student'
    create :correct_submission, user: u2, course: c, exercise: e2
    create :correct_submission, user: u2, course: c, exercise: e1
    create :wrong_submission, user: u2, course: c, exercise: e1
    u3 = create :user
    CourseMembership.create user: u3, course: c, status: 'student'
    create :wrong_submission, user: u3, course: c, exercise: e1
    create :activity_read_state, user: u3, course: c, activity: a1
    create :activity_read_state, user: u3, course: c, activity: a2
    u4 = create :user
    CourseMembership.create user: u4, course: c, status: 'student'
    create :correct_submission, user: u4, course: c, exercise: e1
    create :correct_submission, user: u4, course: c, exercise: e2
    u5 = create :user
    CourseMembership.create user: u5, course: c, status: 'student'
    create :correct_submission, user: u5, course: c, exercise: e1
    create :correct_submission, user: u5, course: c, exercise: e2
    create :activity_read_state, user: u5, course: c, activity: a1
    create :activity_read_state, user: u5, course: c, activity: a2

    assert_equal [u1.id, u2.id, u3.id, u4.id, u5.id], User.in_course(c).order_by_solved_exercises_in_course('ASC', c).pluck(:id)
    assert_equal [u5.id, u4.id, u3.id, u2.id, u1.id], User.in_course(c).order_by_solved_exercises_in_course('DESC', c).pluck(:id)
  end



  test 'should be able to order by progress' do
    User.destroy_all
    c = create :course
    e1 = create :exercise
    e2 = create :exercise

    u1 = create :user
    u2 = create :user
    create :correct_submission, user: u2, course: c, exercise: e1
    u3 = create :user
    create :correct_submission, user: u3, exercise: e1
    create :wrong_submission, user: u3, course: c, exercise: e2
    u4 = create :user
    create :wrong_submission, user: u4, course: c, exercise: e1
    create :correct_submission, user: u4, course: c, exercise: e1
    create :correct_submission, user: u4, course: c, exercise: e2

    assert_equal [u1.id, u2.id, u3.id, u4.id], User.order_by_progress('ASC').pluck(:id)
    assert_equal [u4.id, u3.id, u2.id, u1.id], User.order_by_progress('DESC').pluck(:id)
    assert_equal [u1.id, u3.id, u2.id, u4.id], User.order_by_progress('ASC', c).pluck(:id)
    assert_equal [u4.id, u2.id, u3.id, u1.id], User.order_by_progress('DESC', c).pluck(:id)
  end
end

class UserHasManyTest < ActiveSupport::TestCase
  def setup
    @user = users(:student)
    @administrating_course = courses(:course1)
    membership_course_admin = CourseMembership.new(user: @user, course: @administrating_course, status: 'course_admin')
    @administrating_course.course_memberships.concat(membership_course_admin)
    @favorite_course = create :course
    @membership_favorite = CourseMembership.new(user: @user, course: @favorite_course, status: 'student', favorite: true)
    @favorite_course.course_memberships.concat(@membership_favorite)
    @enrolled_course = create :course, users: [@user]
    @unsubscribed_course = create :course
    membership_unsubscribed = CourseMembership.new(user: @user, course: @unsubscribed_course, status: 'unsubscribed')
    @unsubscribed_course.course_memberships.concat(membership_unsubscribed)
    @pending_course = create :course
    membership_pending = CourseMembership.new(user: @user, course: @pending_course, status: 'pending')
    @pending_course.course_memberships.concat(membership_pending)
  end

  test 'subscribed_courses should return the courses in which the user is a student or course admin' do
    subscribed_courses = @user.subscribed_courses.pluck(:id)
    assert_equal true, subscribed_courses.include?(@enrolled_course.id)
    assert_equal true, subscribed_courses.include?(@administrating_course.id)
    assert_equal true, subscribed_courses.include?(@favorite_course.id)
    assert_equal 3, subscribed_courses.count
  end

  test 'course functions should work' do
    # favorite_courses should return the courses in which the user has set as favorite
    assert_equal [@favorite_course], @user.favorite_courses

    # administrating_courses should return the courses in which the user is an admin
    assert_equal [@administrating_course], @user.administrating_courses

    # pending_courses should return the courses in which the user is a student
    assert_equal [@pending_course], @user.pending_courses

    # unsubscribed_courses should return the courses in which the user is a student
    assert_equal [@unsubscribed_course], @user.unsubscribed_courses
  end

  test 'enrolled_courses should return the courses in which the user is a student' do
    enrolled_courses = @user.enrolled_courses.pluck(:id)
    assert_equal true, enrolled_courses.include?(@enrolled_course.id)
    assert_equal true, enrolled_courses.include?(@favorite_course.id)
    assert_equal 2, enrolled_courses.count
  end

  test 'drawer_courses should not return courses if not subscribed for any' do
    user = create :user
    assert user.courses.empty?
    assert user.drawer_courses.empty?
  end

  test 'drawer_courses should return favorite courses' do
    assert_equal [@favorite_course], @user.drawer_courses

    @membership_favorite.update(favorite: false)
    assert_not_equal [@favorite_course], @user.drawer_courses

    @user.courses.each { |c| c.update(year: '1') }
    assert_equal @user.subscribed_courses.length, @user.drawer_courses.length

    @user.subscribed_courses.first.update(year: '2')
    assert_equal [@user.subscribed_courses.first], @user.drawer_courses
  end

  test 'user should be removed after merge' do
    u1 = create :user
    u2 = create :user
    u1.merge_into(u2)

    assert_not u1.persisted?
  end

  test 'merge should fail if institutions are different' do
    i1 = create :institution
    i2 = create :institution
    u1 = create :user, institution: i1
    u2 = create :user, institution: i2

    result = u1.merge_into(u2)

    assert_not result
    assert u1.persisted?
  end

  test 'merge should succeed if only one institution is set' do
    i1 = create :institution
    u1 = create :user, institution: i1
    u2 = create :user

    result = u1.merge_into(u2)

    assert result
    assert_not u1.persisted?
    assert_equal i1, u2.institution
  end

  test 'merge should fail if permissions are different' do
    u1 = create :user, permission: 'student'
    u2 = create :user, permission: 'staff'

    result = u1.merge_into(u2)

    assert_not result
    assert u1.persisted?
  end

  test 'merge should take highest permission if force is used' do
    u1 = create :user, permission: 'zeus'
    u2 = create :user, permission: 'staff'

    result = u1.merge_into(u2, force: true)

    assert result
    assert_not u1.persisted?
    assert_equal 'zeus', u2.permission
  end

  test 'merge should transfer all associated objects to the other user' do
    u1 = create :user
    u2 = create :user

    [u1, u2].each do |u|
      c = create :course
      s = create :submission, user: u, course: c
      create :api_token, user: u
      create :event, user: u
      create :export, user: u
      create :notification, user: u
      create :annotation, user: u, submission: s
      create :question, submission: s
    end

    result = u1.merge_into(u2)

    assert result
    assert_not u1.persisted?
    assert_equal 2, u2.submissions.count
    assert_equal 2, u2.api_tokens.count
    assert_equal 2, u2.events.count
    assert_equal 2, u2.exports.count
    assert_equal 4, u2.notifications.count
    assert_equal 4, u2.annotations.count
    assert_equal 2, u2.questions.count
  end

  test 'merge should only transfer unique read states to the other user' do
    u1 = create :user
    u2 = create :user

    a1 = create :content_page
    a2 = create :content_page
    create :activity_read_state, user: u1, activity: a1
    create :activity_read_state, user: u2, activity: a1
    create :activity_read_state, user: u1, activity: a2

    result = u1.merge_into(u2)

    assert result
    assert_not u1.persisted?
    assert_equal 2, u2.activity_read_states.count
  end

  test 'merge should only transfer unique identities to the other user' do
    u1 = create :user
    u2 = create :user

    p1 = create :provider
    p2 = create :provider
    Identity.create user: u1, provider: p1, identifier: 'a'
    Identity.create user: u2, provider: p1, identifier: 'b'
    Identity.create user: u1, provider: p2, identifier: 'c'

    result = u1.merge_into(u2)

    assert result
    assert_not u1.persisted?
    assert_equal 2, u2.identities.count
  end

  test 'merge should only transfer unique repositories to the other user' do
    u1 = create :user
    u2 = create :user

    r1 = create :repository, :git_stubbed
    r2 = create :repository, :git_stubbed
    RepositoryAdmin.create user: u1, repository: r1
    RepositoryAdmin.create user: u2, repository: r1
    RepositoryAdmin.create user: u1, repository: r2

    result = u1.merge_into(u2)

    assert result
    assert_not u1.persisted?
    assert_equal 2, u2.repository_admins.count
  end

  test 'merge should only transfer unique evaluations to the other user' do
    u1 = create :user
    u2 = create :user

    e1 = create :evaluation
    e2 = create :evaluation
    EvaluationUser.create user: u1, evaluation: e1
    EvaluationUser.create user: u2, evaluation: e1
    EvaluationUser.create user: u1, evaluation: e2

    result = u1.merge_into(u2)

    assert result
    assert_not u1.persisted?
    assert_equal 2, u2.evaluation_users.count
  end

  test 'merge should transfer course membership with most rights to the other user' do
    u1 = create :user
    u2 = create :user

    c1 = create :course
    c2 = create :course
    c3 = create :course
    c4 = create :course
    c5 = create :course
    CourseMembership.create user: u1, course: c1, status: 'student', favorite: true
    CourseMembership.create user: u1, course: c2, status: 'pending'
    CourseMembership.create user: u1, course: c3, status: 'unsubscribed'
    CourseMembership.create user: u1, course: c4, status: 'student'
    CourseMembership.create user: u1, course: c5, status: 'course_admin'

    CourseMembership.create user: u2, course: c2, status: 'pending'
    CourseMembership.create user: u2, course: c3, status: 'course_admin', favorite: true
    CourseMembership.create user: u2, course: c4, status: 'unsubscribed'
    CourseMembership.create user: u2, course: c5, status: 'student'

    result = u1.merge_into(u2)

    assert_equal 0, u1.course_memberships.count

    assert result
    assert_not u1.persisted?
    assert_equal 5, u2.course_memberships.count
    assert_equal 4, u2.subscribed_courses.count
    assert_equal 2, u2.favorite_courses.count
    assert_equal 2, u2.administrating_courses.count
    assert_equal 2, u2.enrolled_courses.count
    assert_equal 1, u2.pending_courses.count
    assert_equal 0, u2.unsubscribed_courses.count
  end

  test 'merge should transfer update cached values' do
    u1 = create :user
    u2 = create :user

    c = create :course
    c2 = create :course
    CourseMembership.create user: u1, course: c, status: 'student'
    CourseMembership.create user: u2, course: c, status: 'student'
    s1 = create :series, course: c, exercise_count: 0
    s2 = create :series, course: c2,  exercise_count: 0
    e1 = create :exercise
    e2 = create :exercise
    e3 = create :exercise
    SeriesMembership.create series: s1, activity: e1
    SeriesMembership.create series: s1, activity: e2
    SeriesMembership.create series: s2, activity: e3
    create :correct_submission, user: u2, course: c, exercise: e1
    create :wrong_submission, user: u2, course: c, exercise: e2
    create :correct_submission, user: u1, course: c, exercise: e1
    create :correct_submission, user: u1, course: c, exercise: e2
    create :wrong_submission, user: u1, course: c2, exercise: e3

    assert_equal 3, c.correct_solutions
    assert_equal 2, c.subscribed_members_count
    assert_equal 1, u2.correct_exercises
    assert_equal 2, u2.attempted_exercises
    assert_equal 2, e1.users_correct
    assert_equal 2, e1.users_tried
    assert_equal false, s1.completed?(user: u2)
    assert_equal false, s2.started?(user: u2)
    assert_equal false, s2.wrong?(user: u2)

    result = u1.merge_into(u2)

    assert result
    assert_not u1.persisted?
    assert_equal 1, c.subscribed_members_count
    assert_equal 2, c.correct_solutions
    assert_equal 2, u2.correct_exercises
    assert_equal 3, u2.attempted_exercises
    assert_equal 1, e1.users_correct
    assert_equal 1, e1.users_tried
    assert_equal true, s1.completed?(user: u2)
    assert_equal true, s2.started?(user: u2)
    assert_equal true, s2.wrong?(user: u2)
  end
end
