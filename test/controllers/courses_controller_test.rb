require 'testhelpers/crud_helper'
require 'test_helper'

class CoursesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Course, attrs: %i[name year description visibility registration]

  setup do
    @instance = create(:course)
    sign_in create(:zeus)
  end

  test_crud_actions

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
    @course = create :course, series_count: 1, exercises_per_series: 1, submissions_per_exercise: 1
    _zeus_extern = create :zeus
    _zeus_intern = create :zeus

    @course.administrating_members.concat(create_normies)

    @course_admins = @course.administrating_members
    @admins = @course_admins

    @students = create_normies
    @course.enrolled_members.concat(@students)

    @unsubscribed = create_normies
    @course.unsubscribed_members.concat(@unsubscribed)

    @pending = create_normies
    @course.pending_members.concat(@pending)

    @subscribed = @students + @course_admins
    @externals = create_normies
    @not_subscribed = @externals + @unsubscribed + @pending

    @not_admins = @students + @unsubscribed + @pending + @externals + [nil]
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
    with_users_signed_in @not_subscribed do |who, user|
      post subscribe_course_url(@course, format: :json)
      assert @course.subscribed_members.include?(user), "#{who} should be able to subscribe"
    end
  end

  test 'subscribe should redirect to course' do
    with_users_signed_in @not_subscribed do |who|
      post subscribe_course_url(@course)
      assert_redirected_to @course, "#{who} should be redirected"
    end
  end

  test 'should get course page with secret' do
    with_users_signed_in @not_subscribed do |who, user|
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
    with_users_signed_in @course.users do |who|
      assert_difference('CourseMembership.count', 0, "#{who} should not be able to create a second membership") do
        post subscribe_course_url(@course, format: :json)
      end
    end
  end

  test 'unsubscribed user should be able to resubscribe' do
    with_users_signed_in @unsubscribed do |who, user|
      assert_not user.member_of?(@course), "#{who} was already a member"
      post subscribe_course_url(@course, format: :json)
      assert user.member_of?(@course), "#{who} should be a member"
    end
  end

  test 'should get course scoresheet as course admin in html format' do
    sign_in @course_admins.first
    get scoresheet_course_url(@course)
    assert_response :success, 'course_admin should be able to get course scoresheet'
  end

  test 'should get course scoresheet as course admin in csv format' do
    sign_in @course_admins.first
    get scoresheet_course_url(@course, format: :csv)
    assert_response :success, 'course_admin should be able to get course scoresheet'
  end

  test 'should get course scoresheet as course admin in json format' do
    sign_in @course_admins.first
    get scoresheet_course_url(@course, format: :json)
    assert_response :success, 'course_admin should be able to get course scoresheet'
  end

  test 'should not get course scoresheet as normal user' do
    sign_in @students.first
    get scoresheet_course_url(@course)
    assert_response :redirect, 'student should not be able to get course scoresheet'
  end

  test 'visiting registration page when subscribed should redirect' do
    with_users_signed_in @subscribed do |who|
      get registration_course_url(@course, @course.secret, format: :json)
      assert_redirected_to @course, "#{who} should be redirected"
    end
  end

  test 'zeus visiting registration page when subscribed should redirect' do
    zeus = create :zeus
    @course.subscribed_members << zeus
    sign_in zeus

    get registration_course_url(@course, @course.secret)
    assert_redirected_to @course, 'zeus should be redirected'
  end

  test 'should not subscribe to hidden course with invalid, empty or absent secret' do
    @course.update(visibility: 'hidden')
    with_users_signed_in @not_subscribed do |who, user|
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
    with_users_signed_in @not_subscribed do |who, user|
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
    with_users_signed_in @not_subscribed do |who, user|
      post subscribe_course_url(@course, format: :json)
      assert @course.pending_members.include?(user), "#{who} should be pending"
    end
  end

  test 'should be able to withdraw registration request' do
    @course.update(moderated: true)
    with_users_signed_in @pending do |who, user|
      post unsubscribe_course_url(@course, format: :json)
      assert_not @course.pending_members.include?(user), "#{who} should not be pending anymore"
    end
  end

  test 'should be on pending list with moderated and hidden course' do
    @course.update(moderated: 'true', visibility: 'hidden')
    with_users_signed_in @not_subscribed do |who, user|
      post subscribe_course_url(@course, secret: @course.secret, format: :json)
      assert @course.pending_members.include?(user), "#{who} should be pending"
    end
  end

  test 'externals (and not logged in) should be able to see course' do
    with_users_signed_in(@externals + [nil]) do |who|
      get course_url(@course)
      assert_response :success, "#{who} should be able to see course"
    end
  end

  test 'externals (and not logged in) should not be able to see hidden course' do
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
    with_users_signed_in @admins do |who|
      students = create_list :student, 10
      @course.pending_members = students
      post mass_accept_pending_course_url(@course)
      @course.reload
      assert @course.pending_members.empty?, "#{who} should be able to accept pending"
      assert (students - @course.enrolled_members), "students should be enrolled for #{who}"
    end
  end

  test 'admin should be able to mass decline pending members' do
    with_users_signed_in @admins do |who|
      students = create_list :student, 10
      @course.pending_members = students

      submission = create :submission, course: @course
      @course.pending_members << submission.user

      post mass_decline_pending_course_url(@course)
      @course.reload
      assert @course.pending_members.empty?, "#{who} should be able to decline pending"
      assert CourseMembership.where(course: @course, user: students).empty?, "memberships should be deleted for #{who}"

      assert @course.unsubscribed_members.include?(submission.user)
    end
  end

  test 'students should not be able to accept pending members' do
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
    @course = create :course
    admin = create :zeus
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
    # add a course admin to prevent the last course admin has to unsubscribe
    @course.administrating_members << create(:zeus)
    @course.save
    with_users_signed_in @subscribed do |who, user|
      post unsubscribe_course_url(@course)
      # our users do not have submissions, so their membership is deleted
      assert_not @course.users.include?(user), "#{who} should be unsubscribed"
    end
  end

  test 'unsubscribing user with solutions for course should keep membership' do
    user = @students.first
    sign_in user
    create :correct_submission,
           user: user,
           course: @course

    post unsubscribe_course_url(@course)
    assert @course.unsubscribed_members.include?(user)
  end

  test 'unsubscribing user without solutions for course should delete membership' do
    user = @students.first
    sign_in user

    post unsubscribe_course_url(@course)
    assert_not @course.users.include?(user)
  end

  test 'admins should be able to list members' do
    with_users_signed_in @admins do |who|
      get course_members_url(@course), xhr: true
      assert_response :success, "#{who} should be able to list members"
    end
  end

  test 'not-admins should not be able to list members' do
    with_users_signed_in @not_admins do |who|
      get course_members_url(@course), xhr: true
      assert (response.forbidden? || response.unauthorized?), "#{who} should not be able to list members"
    end
  end

  test 'admins should be able to view members in course' do
    with_users_signed_in @admins do |who|
      @students.each do |view|
        get course_member_url(@course, view), xhr: true
        assert_response :success, "#{who} should be able to view #{view.permission}:#{view.membership_status_for(@course)}"
      end
    end
  end

  test 'not-admins should not be able to view members in course except themselves' do
    with_users_signed_in @not_admins do |who, signed_in|
      @course.users.reject { |u| u == signed_in }.each do |view|
        get course_member_url(@course, view), xhr: true
        assert (response.forbidden? || response.unauthorized?), "#{who} should not be able to view #{view}"
      end
    end
  end

  test 'admins should be able to view their hidden course in the course overview' do
    @course.update(visibility: 'hidden')
    with_users_signed_in @admins do |who|
      get courses_url, params: { format: :json }
      courses = JSON.parse response.body
      assert courses.any? { |c| c['id'] == @course.id }, "#{who} should be able to see a hidden course of which he is course administrator"
    end
  end

  test 'not admins should not be able to view hidden courses' do
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

  test 'users should be able to favorite subscribed courses' do
    user = @students.first
    sign_in user

    post favorite_course_url(@course)
    assert CourseMembership.find_by(user: user, course: @course).favorite
  end

  test 'users should be able to unfavorite favorited courses' do
    user = @students.first
    sign_in user

    post favorite_course_url(@course)
    post unfavorite_course_url(@course)
    assert_not CourseMembership.find_by(user: user, course: @course).favorite
  end

  test 'users should not be able to favorite unsubscribed courses' do
    user = @students.first
    sign_in user

    post unsubscribe_course_url(@course)
    post favorite_course_url(@course)
    assert_not response.successful?
  end

  test 'users should not be able to unfavorite unsubscribed courses' do
    user = @students.first
    sign_in user

    post unsubscribe_course_url(@course)
    post unfavorite_course_url(@course)
    assert_not response.successful?
  end

  test 'subscribing to a moderated course when already subscribed should not change status' do
    user = @students.first
    course = create :course, moderated: true
    course.subscribed_members << user

    sign_in user
    post subscribe_course_url(course)
    assert_redirected_to course
    assert course.subscribed_members.include?(user)
  end

  test 'a course copied by a regular student should not include hidden/closed series' do
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
    @course.update(visibility: :hidden)
    user = @externals.first
    sign_in user
    get course_url(@course, secret: @course.secret)
    assert response.body.include?(subscribe_course_path(@course, secret: @course.secret))
  end

  test 'visible_for_institution course page shown to unsubscribed student of different institution should include registration url with secret' do
    @course.update(visibility: :visible_for_institution, institution: (create :institution))
    user = @externals.first
    user.update(institution: (create :institution))
    sign_in user
    get course_url(@course, secret: @course.secret)
    assert response.body.include?(subscribe_course_path(@course, secret: @course.secret))
  end

  test 'visible_for_institution course page shown to unsubscribed student of same institution should not include registration url with secret' do
    @course.update(visibility: :visible_for_institution, institution: (create :institution))
    user = @externals.first
    user.update(institution: @course.institution)
    sign_in user
    get course_url(@course, secret: @course.secret)
    assert_not response.body.include?(subscribe_course_path(@course, secret: @course.secret))
  end

  test 'should not destroy course as student' do
    sign_in @students.first
    delete course_url(@course)
    assert_not response.successful?
  end

  test 'should destroy course as course admin' do
    sign_in @course_admins.first
    assert_difference 'Course.count', -1 do
      delete course_url(@course)
    end
    assert response.body.include?(courses_url)
  end

  test 'should not destroy course as course admin if too many submissions' do
    create_list :series, 1, course: @course, exercise_count: 1, exercise_submission_count: CoursePolicy::MAX_SUBMISSIONS_FOR_DESTROY + 1
    sign_in @course_admins.first
    delete course_url(@course)
    assert_not response.successful?
  end

  test 'should destroy course as zeus even if too many submissions' do
    create_list :series, 1, course: @course, exercise_count: 1, exercise_submission_count: CoursePolicy::MAX_SUBMISSIONS_FOR_DESTROY + 1
    admin = create :zeus
    sign_in admin
    assert_difference 'Course.count', -1 do
      delete course_url(@course)
    end
    assert response.body.include?(courses_url)
  end
end
