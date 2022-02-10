require 'testhelpers/crud_helper'
require 'test_helper'

class CoursesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Course, attrs: %i[name year description visibility registration]

  setup do
    @instance = courses(:course1)
    sign_in users(:zeus)
  end

  test_crud_actions

  test 'should render with inaccessible activities' do
    @instance.series << create(:series)
    @instance.series.first.activities << create(:exercise, access: :private)
    get course_url(@instance)
    assert_response :success
  end

  test 'should render with inaccessible activities when no user' do
    @instance.series << create(:series)
    @instance.series.first.activities << create(:exercise, access: :private)
    sign_out :user
    get course_url(@instance)
    assert_response :success
  end

  test 'should reset token' do
    old_secret = @instance.secret
    post reset_token_course_url(@instance)
    assert_not_equal old_secret, @instance.reload.secret
  end
end

class CoursesPermissionControllerTest < ActionDispatch::IntegrationTest
  def create_normies
    [create(:staff), create(:student)]
  end

  setup do
    @course = courses(:course1)

    @subscribed = []
    @not_admins = []
    @not_subscribed = []
  end

  def full_setup
    add_admins
    add_students
    add_unsubscribed
    add_pending
    add_externals
  end

  def add_admins
    @course.administrating_members.concat(create_normies)

    @course_admins = @course.administrating_members
    @admins = @course_admins
    @subscribed.concat(@course_admins)
  end

  def add_students
    @students = [users(:student), users(:staff)]
    @course.enrolled_members.concat(@students)

    @subscribed.concat(@students)
    @not_admins.concat(@students)
  end

  def add_unsubscribed
    @unsubscribed = create_normies
    @course.unsubscribed_members.concat(@unsubscribed)

    @not_subscribed.concat(@unsubscribed)
    @not_admins.concat(@unsubscribed)
  end

  def add_pending
    @pending = create_normies
    @course.pending_members.concat(@pending)

    @not_subscribed.concat(@pending)
    @not_admins.concat(@pending)
  end

  def add_externals
    @externals = create_normies + [nil]

    @not_subscribed.concat(@externals)
    @not_admins.concat(@externals)
  end

  def add_subscribed
    add_admins
    add_students
  end

  def add_not_subscribed
    add_unsubscribed
    add_pending
    add_externals
  end

  def add_not_admins
    add_students
    add_pending
    add_externals
  end

  # execute the block with each user signed in
  # if a user is nil, nobody is signed in
  def with_users_signed_in(users)
    raise 'argument array should not be empty' if users.empty?

    users.each do |user|
      who = if user
              "#{user.permission}:#{user.membership_status_for(@course)}"
            else
              'not signed in'
            end
      sign_in user if user
      yield who, user
      sign_out :user
    end
  end

  test 'should subscribe current_user to course' do
    add_not_subscribed
    with_users_signed_in @not_subscribed.compact do |who, user|
      post subscribe_course_url(@course, format: :json)
      assert @course.subscribed_members.include?(user), "#{who} should be able to subscribe"
    end
  end

  test 'subscribe should redirect to course' do
    add_not_subscribed
    with_users_signed_in @not_subscribed.compact do |who|
      post subscribe_course_url(@course)
      assert_redirected_to @course, "#{who} should be redirected"
    end
  end

  test 'should get course page with secret' do
    add_not_subscribed
    with_users_signed_in @not_subscribed.compact do |who, user|
      %w[visible_for_all visible_for_institution hidden].product(%w[open_for_all open_for_institution closed], [true, false]).each do |v, r, m|
        @course.update(visibility: v, registration: r, moderated: m)
        get course_url(@course, secret: @course.secret, format: :json)
        assert_response :success, "#{who} should get registration page"
        # GET should not subscribe
        assert_not user.member_of?(@course), "#{who} should not be registered"
      end
    end
  end

  test 'should not subscribe when already subscribed' do
    full_setup
    with_users_signed_in @course.users do |who|
      assert_difference('CourseMembership.count', 0, "#{who} should not be able to create a second membership") do
        post subscribe_course_url(@course, format: :json)
      end
    end
  end

  test 'unsubscribed user should be able to resubscribe' do
    add_unsubscribed
    with_users_signed_in @unsubscribed do |who, user|
      assert_not user.member_of?(@course), "#{who} was already a member"
      post subscribe_course_url(@course, format: :json)
      assert user.courses.include?(@course), "#{who} should be a member"
    end
  end

  test 'should get course scoresheet as course admin' do
    add_admins
    sign_in @course_admins.first
    get scoresheet_course_url(@course)
    assert_response :success, 'course_admin should be able to get course scoresheet'

    get scoresheet_course_url(@course, format: :csv)
    assert_response :success, 'course_admin should be able to get course scoresheet'

    get scoresheet_course_url(@course, format: :json)
    assert_response :success, 'course_admin should be able to get course scoresheet'
  end

  test 'should not get course scoresheet as normal user' do
    add_students
    sign_in @students.first
    get scoresheet_course_url(@course)
    assert_response :redirect, 'student should not be able to get course scoresheet'
  end

  test 'visiting registration page when subscribed should redirect' do
    @course = create :course, series_count: 1, activities_per_series: 1, submissions_per_exercise: 1
    add_subscribed
    with_users_signed_in @subscribed do |who|
      get registration_course_url(@course, @course.secret, format: :json)
      assert_redirected_to @course, "#{who} should be redirected"
    end
  end

  test 'zeus visiting registration page when subscribed should redirect' do
    @course = create :course, series_count: 1, activities_per_series: 1, submissions_per_exercise: 1
    add_subscribed
    zeus = users(:zeus)
    @course.subscribed_members << zeus
    sign_in zeus

    get registration_course_url(@course, @course.secret)
    assert_redirected_to @course, 'zeus should be redirected'
  end

  test 'should not subscribe to hidden course with invalid, empty or absent secret' do
    @course.update(visibility: 'hidden')
    add_not_subscribed
    with_users_signed_in @not_subscribed.compact do |who, user|
      post subscribe_course_url(@course, secret: 'the cake is a lie')
      assert_not user.member_of?(@course), "#{who} with invalid secret"

      post subscribe_course_url(@course, secret: '')
      assert_not user.member_of?(@course), "#{who} with empty secret"

      post subscribe_course_url(@course)
      assert_not user.member_of?(@course), "#{who} without secret"
    end
  end

  test 'should not subscribe to closed course' do
    @course.update(registration: 'closed')
    add_not_subscribed
    with_users_signed_in @not_subscribed.compact do |who, user|
      @course.update(visibility: 'visible_for_all')
      post subscribe_course_url(@course)
      assert_not user.member_of?(@course), "#{who} should not be subscribed"

      @course.update(visibility: 'hidden')
      post subscribe_course_url(@course, secret: @course.secret)
      assert_not user.member_of?(@course), "#{who} should not be subscribed"
    end
  end

  test 'should not be on pending list with closed course' do
    @course.update(registration: 'closed')
    add_externals
    with_users_signed_in @externals do |who, user|
      @course.update(visibility: 'visible_for_all')
      post subscribe_course_url(@course)
      assert_not @course.users.include?(user), "#{who} should not have a membership"

      @course.update(visibility: 'hidden')
      post subscribe_course_url(@course, secret: @course.secret)
      assert_not @course.users.include?(user), "#{who} should not have a membership"
    end
  end

  test 'should be on pending list with moderated course' do
    @course.update(moderated: true)
    add_not_subscribed
    with_users_signed_in @not_subscribed.compact do |who, user|
      post subscribe_course_url(@course, format: :json)
      assert @course.pending_members.include?(user), "#{who} should be pending"
    end
  end

  test 'should be able to withdraw registration request' do
    @course.update(moderated: true)
    add_pending
    with_users_signed_in @pending do |who, user|
      post unsubscribe_course_url(@course, format: :json)
      assert_not @course.pending_members.include?(user), "#{who} should not be pending anymore"
    end
  end

  test 'should be on pending list with moderated and hidden course' do
    @course.update(moderated: 'true', visibility: 'hidden')
    add_not_subscribed
    with_users_signed_in @not_subscribed.compact do |who, user|
      post subscribe_course_url(@course, secret: @course.secret, format: :json)
      assert @course.pending_members.include?(user), "#{who} should be pending"
    end
  end

  test 'externals (and not logged in) should be able to see course' do
    add_externals
    with_users_signed_in(@externals + [nil]) do |who|
      get course_url(@course)
      assert_response :success, "#{who} should be able to see course"
    end
  end

  test 'externals (and not logged in) should not be able to see hidden course' do
    @course = create :course, series_count: 1, activities_per_series: 1, submissions_per_exercise: 1
    add_externals
    @course.update(visibility: 'hidden')
    with_users_signed_in(@externals + [nil]) do |who, user|
      get course_url(@course)
      if user
        assert_redirected_to :root, "#{who} should not be able to see course"
      else
        assert_redirected_to :sign_in, 'not logged in should be redirected to login page'
      end
    end
  end

  test 'admin should be able to accept or decline pending members' do
    add_admins
    add_pending
    with_users_signed_in @admins do |who|
      acceptme = create :student
      declineme = create :student
      @course.pending_members << acceptme << declineme

      post update_membership_course_url(@course, user: acceptme, status: 'student')
      assert @course.enrolled_members.include?(acceptme), "#{who} student not enrolled"

      post update_membership_course_url(@course, user: declineme, status: 'unsubscribed')
      assert_not @course.enrolled_members.include?(declineme), "#{who} student not unsubscribed"
    end
  end

  test 'admin should be able to mass accept pending members' do
    add_admins
    add_pending
    with_users_signed_in @admins do |who|
      students = create_list :student, 2
      @course.pending_members = students
      post mass_accept_pending_course_url(@course)
      @course.reload
      assert @course.pending_members.empty?, "#{who} should be able to accept pending"
      assert (students - @course.enrolled_members), "students should be enrolled for #{who}"
    end
  end

  test 'admin should be able to mass decline pending members' do
    add_admins
    add_pending
    with_users_signed_in @admins do |who|
      students = create_list :student, 2
      @course.pending_members = students

      submission = create :submission, :generated_user, course: @course
      @course.pending_members << submission.user

      post mass_decline_pending_course_url(@course)
      @course.reload
      assert @course.pending_members.empty?, "#{who} should be able to decline pending"
      assert CourseMembership.where(course: @course, user: students).empty?, "memberships should be deleted for #{who}"

      assert @course.unsubscribed_members.include?(submission.user)
    end
  end

  test 'students should not be able to accept pending members' do
    add_students
    add_pending
    with_users_signed_in @students do |who|
      acceptme = create :student
      declineme = create :student
      @course.pending_members << acceptme << declineme

      post update_membership_course_url(@course, user: acceptme, status: 'student')
      assert_not @course.enrolled_members.include?(acceptme), "#{who} student should not be enrolled"

      post update_membership_course_url(@course, user: acceptme, status: 'unsubscribed')
      assert_not @course.unsubscribed_members.include?(acceptme), "#{who} student should not be unsubscribed"
    end
  end

  test 'course admin staff and zeus should be able to promote and fire members' do
    add_admins
    add_students
    super_admins = @admins.reject(&:student?)
    with_users_signed_in super_admins do |who|
      members = create_normies
      @course.enrolled_members.concat members
      members.each do |u|
        post update_membership_course_url(@course, user: u, status: 'course_admin')
        assert @course.reload.administrating_members.include?(u), "#{who} should be able to promote members"

        post update_membership_course_url(@course, user: u, status: 'student')
        assert @course.reload.enrolled_members.include?(u), "#{who} should be able to demote members"
      end
    end
  end

  test 'all course admins should be able to promote or fire members' do
    full_setup
    student_admins = @admins.select(&:student?)
    with_users_signed_in student_admins do |who|
      members_student = create_normies
      members_admin = create_normies
      @course.enrolled_members.concat members_student
      @course.administrating_members.concat members_admin
      members_student.each do |u|
        post update_membership_course_url(@course, user: u, status: 'course_admin')
        assert @course.reload.administrating_members.include?(u), "#{who} should be able to promote members"
      end
      members_admin.each do |u|
        post update_membership_course_url(@course, user: u, status: 'student')
        assert @course.reload.enrolled_members.include?(u), "#{who} should be able to demote members"
      end
    end
    with_users_signed_in @not_admins do |who|
      members_student = create_normies
      members_admin = create_normies
      @course.enrolled_members.concat members_student
      @course.administrating_members.concat members_admin
      members_student.each do |u|
        post update_membership_course_url(@course, user: u, status: 'course_admin')
        assert_not @course.reload.administrating_members.include?(u), "#{who} should not be able to promote members"
      end
      members_admin.each do |u|
        post update_membership_course_url(@course, user: u, status: 'student')
        assert_not @course.reload.enrolled_members.include?(u), "#{who} should not be able to demote members"
      end
    end
  end

  test 'last course admin should go down with his ship' do
    @course = courses(:course1)
    admin = users(:zeus)
    @course.administrating_members << admin
    sign_in admin

    post unsubscribe_course_url(@course)

    assert @course.administrating_members.include?(admin)

    %w[student pending unsubscribed].each do |s|
      post update_membership_course_url(@course, user: admin, status: s)
      assert @course.administrating_members.include?(admin)
    end
  end

  test 'members should be able to unsubscribe' do
    add_students
    # add a course admin to prevent the last course admin has to unsubscribe
    @course.administrating_members << users(:zeus)
    @course.save
    with_users_signed_in @subscribed do |who, user|
      post unsubscribe_course_url(@course)
      # our users do not have submissions, so their membership is deleted
      assert_not @course.users.include?(user), "#{who} should be unsubscribed"
    end
  end

  test 'unsubscribing user with solutions for course should keep membership' do
    add_students
    user = @students.first
    sign_in user
    create :correct_submission,
           user: user,
           course: @course

    post unsubscribe_course_url(@course)
    assert @course.unsubscribed_members.include?(user)
  end

  test 'unsubscribing user without solutions for course should delete membership' do
    add_students
    user = @students.first
    sign_in user

    post unsubscribe_course_url(@course)
    assert_not @course.users.include?(user)
  end

  test 'admins should be able to list members' do
    add_admins
    with_users_signed_in @admins do |who|
      get course_members_url(@course), xhr: true
      assert_response :success, "#{who} should be able to list members"
    end
  end

  test 'not-admins should not be able to list members' do
    add_not_admins
    with_users_signed_in @not_admins do |who|
      get course_members_url(@course), xhr: true
      assert (response.forbidden? || response.unauthorized?), "#{who} should not be able to list members"
    end
  end

  test 'admins should be able to view members in course' do
    add_admins
    add_students
    with_users_signed_in @admins do |who|
      @students.each do |view|
        get course_member_url(@course, view), xhr: true
        assert_response :success, "#{who} should be able to view #{view.permission}:#{view.membership_status_for(@course)}"
      end
    end
  end

  test 'not-admins should not be able to view members in course except themselves' do
    add_not_admins
    with_users_signed_in @not_admins do |who, signed_in|
      @course.users.reject { |u| u == signed_in }.each do |view|
        get course_member_url(@course, view), xhr: true
        assert (response.forbidden? || response.unauthorized?), "#{who} should not be able to view #{view}"
      end
    end
  end

  test 'admins should be able to view their hidden course in the course overview' do
    add_admins
    @course.update(visibility: 'hidden')
    with_users_signed_in @admins do |who|
      get courses_url, params: { format: :json }
      courses = JSON.parse response.body
      assert courses.any? { |c| c['id'] == @course.id }, "#{who} should be able to see a hidden course of which he is course administrator"
    end
  end

  test 'not admins should not be able to view hidden courses' do
    add_not_subscribed
    @course.update(visibility: 'hidden')
    with_users_signed_in @not_subscribed do |who|
      get courses_url, params: { format: :json }
      if response.successful?
        courses = JSON.parse response.body
        assert_not courses.any? { |c| c['id'] == @course.id }, "#{who} should not be able to see a hidden course"
      else
        assert response.forbidden? || response.unauthorized?
      end
    end
  end

  test 'signed out users should be able to see the courses listing' do
    get courses_url
    assert_response :success
    # we only expect the "all courses" and "featured courses" tabs to show for signed out users
    assert_select '#course-tabs li', 2
  end

  test 'users should be able to filter courses' do
    add_subscribed
    c1 = create :course, series_count: 1, activities_per_series: 1, submissions_per_exercise: 1
    c2 = create :course, series_count: 1, activities_per_series: 1, submissions_per_exercise: 1
    user = @subscribed.first
    institution = create :institution
    user.institution = institution
    user.save
    c1.update(institution: institution)
    c2.update(institution: institution)
    sign_in user

    # all courses
    get courses_url, params: { format: :json }
    assert_response :success
    courses = JSON.parse response.body
    assert_equal 3, courses.length
    # my courses
    get courses_url, params: { format: :json, tab: 'my' }
    assert_response :success
    courses = JSON.parse response.body
    assert_equal 1, courses.length
    # institution courses
    get courses_url, params: { format: :json, tab: 'institution' }
    assert_response :success
    courses = JSON.parse response.body
    assert_equal 2, courses.length
  end

  test 'featured courses should only show featured courses' do
    get courses_url, params: { format: :json }
    assert_response :success
    courses = JSON.parse response.body
    assert_equal Course.count, courses.length
    get courses_url, params: { format: :json, tab: 'featured' }
    assert_response :success
    courses = JSON.parse response.body
    assert_equal 0, courses.length
    @course.update(featured: true)
    get courses_url, params: { format: :json, tab: 'featured' }
    assert_response :success
    courses = JSON.parse response.body
    assert_equal 1, courses.length
  end

  test 'users should be able to favorite subscribed courses' do
    add_students
    user = @students.first
    sign_in user

    post favorite_course_url(@course)
    assert CourseMembership.find_by(user: user, course: @course).favorite
  end

  test 'users should be able to unfavorite favorited courses' do
    add_students
    user = @students.first
    sign_in user

    post favorite_course_url(@course)
    post unfavorite_course_url(@course)
    assert_not CourseMembership.find_by(user: user, course: @course).favorite
  end

  test 'users should not be able to favorite unsubscribed courses' do
    add_students
    user = @students.first
    sign_in user

    post unsubscribe_course_url(@course)
    post favorite_course_url(@course)
    assert_not response.successful?
  end

  test 'users should not be able to unfavorite unsubscribed courses' do
    add_students
    user = @students.first
    sign_in user

    post unsubscribe_course_url(@course)
    post unfavorite_course_url(@course)
    assert_not response.successful?
  end

  test 'subscribing to a moderated course when already subscribed should not change status' do
    add_subscribed
    user = @students.first
    course = create :course, moderated: true
    course.subscribed_members << user

    sign_in user
    post subscribe_course_url(course)
    assert_redirected_to course
    assert course.subscribed_members.include?(user)
  end

  test 'a course copied by a regular student should not include hidden/closed series' do
    add_students
    user = @students.first
    user.update(permission: :staff)
    course = create :course
    _series = create :series, course: course, visibility: :hidden

    sign_in user
    new_course = build :course
    post courses_url, params: { course: { name: new_course.name, description: new_course.description, visibility: new_course.visibility, registration: new_course.registration, teacher: new_course.teacher }, copy_options: { base_id: course.id }, format: :json }
    assert_equal 0, Course.find(JSON.parse(response.body)['id']).series.count
  end

  test 'hidden course page shown to unsubscribed student should include registration url with secret' do
    add_externals
    @course.update(visibility: :hidden)
    user = @externals.first
    sign_in user
    get course_url(@course, secret: @course.secret)
    assert response.body.include?(subscribe_course_path(@course, secret: @course.secret))
  end

  test 'visible_for_institution course page shown to unsubscribed student of different institution should include registration url with secret' do
    add_externals
    @course.update(visibility: :visible_for_institution, institution: (create :institution))
    user = @externals.first
    user.update(institution: (create :institution))
    sign_in user
    get course_url(@course, secret: @course.secret)
    assert response.body.include?(subscribe_course_path(@course, secret: @course.secret))
  end

  test 'visible_for_institution course page shown to unsubscribed student of same institution should not include registration url with secret' do
    @course = create :course, series_count: 1, activities_per_series: 1, submissions_per_exercise: 1
    add_externals
    @course.update(visibility: :visible_for_institution, institution: (create :institution))
    user = @externals.first
    user.update(institution: @course.institution)
    sign_in user
    get course_url(@course, secret: @course.secret)
    assert_not response.body.include?(subscribe_course_path(@course, secret: @course.secret))
  end

  test 'should not destroy course as student' do
    add_students
    sign_in @students.first
    delete course_url(@course)
    assert_not response.successful?
  end

  test 'should destroy course as course admin' do
    add_admins
    sign_in @course_admins.first
    assert_difference 'Course.count', -1 do
      delete course_url(@course)
    end
    assert response.body.include?(courses_url)
  end

  test 'should not destroy course as course admin if too many submissions' do
    @course = create :course, series_count: 1, activities_per_series: 1, submissions_per_exercise: 1
    add_admins
    create_list :exercise, 1, series: @course.series, submission_count: CoursePolicy::MAX_SUBMISSIONS_FOR_DESTROY + 1
    sign_in @course_admins.first
    # Assert there are actually too many submissions
    assert_operator @course.submissions.count, :>, CoursePolicy::MAX_SUBMISSIONS_FOR_DESTROY
    delete course_url(@course)
    assert_not response.successful?
  end

  test 'should destroy course as zeus even if too many submissions' do
    @course = create :course, series_count: 1, activities_per_series: 1, submissions_per_exercise: 1
    create_list :exercise, 1, series: @course.series, submission_count: CoursePolicy::MAX_SUBMISSIONS_FOR_DESTROY + 1
    sign_in users(:zeus)
    # Assert there are actually too many submissions
    assert_operator @course.submissions.count, :>, CoursePolicy::MAX_SUBMISSIONS_FOR_DESTROY
    assert_difference 'Course.count', -1 do
      delete course_url(@course)
    end
    assert response.body.include?(courses_url)
  end

  test 'super admins are able to view questions' do
    add_admins
    super_admins = @admins.reject(&:student?)
    with_users_signed_in super_admins do |who|
      # Create some questions so we actually render something
      submission = create :submission, course: @course
      create :question, question_state: :answered, submission: submission
      create :question, question_state: :unanswered, submission: submission
      create :question, question_state: :in_progress, submission: submission
      get questions_course_path(@course)
      assert :ok, "#{who} should be able to view questions"
    end
  end

  test 'not admins cannot view questions' do
    add_not_admins
    with_users_signed_in @not_admins do |who|
      get questions_course_path(@course)
      assert :ok, "#{who} should not be able to view questions"
    end
  end

  test 'question page title is correct' do
    add_admins
    sign_in @admins.first
    get questions_course_path(@course)
    assert_select 'title', /^([^0-9]*)$/

    submission = create :submission, course: @course
    create :question, question_state: :answered, submission: submission
    create :question, question_state: :unanswered, submission: submission
    create :question, question_state: :in_progress, submission: submission
    get questions_course_path(@course)
    assert_select 'title', /\(1\)/
  end

  test 'Icalendar link exports valid and correct ics file' do
    time1 = DateTime.now
    time2 = DateTime.now + 1.day + 1.hour + 1.second
    # Create series
    serie1 = create :series, course_id: @course.id, name: 'open serie1 + deadline', visibility: :open, deadline: time1
    create :series, course_id: @course.id, name: 'open serie no deadline', visibility: :open                   # no deadline
    create :series, course_id: @course.id, name: 'hidden serie', visibility: :hidden, deadline: time1          # hidden
    create :series, course_id: @course.id, name: 'closed serie', visibility: :closed, deadline: time1          # closed
    serie2 = create :series, course_id: @course.id, name: 'open serie2 + deadline', visibility: :open, deadline: time2

    # Check content of the ics file
    get ical_course_url @course, format: :ics
    assert_response :success
    assert_equal 'text/plain; charset=utf-8', response.content_type

    strict_parser = Icalendar::Parser.new(response.body, true)
    cals = strict_parser.parse
    cal = cals.first
    assert_equal "Dodona: #{@course.name}", cal.x_wr_calname.first

    # Last created serie will be listed first
    event1 = cal.events.first
    assert_equal Icalendar::Values::DateTime.new("#{time2.utc.strftime('%Y%m%dT%H%M%S')}Z"), event1.dtstart
    assert_equal Icalendar::Values::DateTime.new("#{time2.utc.strftime('%Y%m%dT%H%M%S')}Z"), event1.dtstart
    assert_equal 'open serie2 + deadline', event1.summary
    expected = I18n.t('courses.ical.serie_deadline', serie_name: serie2.name, course_name: @course.name, serie_url: series_url(serie2))
    assert_equal expected, event1.description
    assert_equal series_url(serie2), event1.url.to_s

    event2 = cal.events.second
    assert_equal Icalendar::Values::DateTime.new("#{time1.utc.strftime('%Y%m%dT%H%M%S')}Z"), event2.dtstart
    assert_equal Icalendar::Values::DateTime.new("#{time1.utc.strftime('%Y%m%dT%H%M%S')}Z"), event2.dtstart
    assert_equal 'open serie1 + deadline', event2.summary
    assert_equal I18n.t('courses.ical.serie_deadline', serie_name: serie1.name, course_name: @course.name, serie_url: series_url(serie1)), event2.description
    assert_equal series_url(serie1), event2.url.to_s

    # Series that are hidden, closed or don't have a deadline should not be present in the ics file
    event3 = cal.events.third
    assert_nil event3
  end
end
