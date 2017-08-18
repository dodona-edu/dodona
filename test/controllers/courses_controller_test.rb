require 'helpers/crud_helper'
require 'test_helper'

class CoursesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Course, attrs: %i[name year description]

  setup do
    @instance = create(:course)
    sign_in create(:zeus)
  end

  test_crud_actions
end

class CoursesPermissionControllerTest < ActionDispatch::IntegrationTest
  def create_normies
    [create(:staff), create(:student)]
  end

  setup do
    @course = create :course
    zeus_extern = create :zeus
    zeus_intern = create :zeus

    @course.administrating_members.concat(create_normies << zeus_intern)

    @course_admins = @course.administrating_members
    @admins = @course_admins + [zeus_extern]

    @students = create_normies
    @course.enrolled_members.concat(@students)

    @unsubscribed = create_normies
    @course.unsubscribed_members.concat(@unsubscribed)

    @pending = create_normies
    @course.pending_members.concat(@pending)

    @subscribed = @students + @course_admins
    @externals = create_normies
    @not_subscribed = @externals + @unsubscribed + @pending + [zeus_extern]

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

  test 'should get scoresheet as admin' do
    with_users_signed_in @admins do |who|
      get scoresheet_course_url(@course)
      assert_response :success, "#{who} should be able to get scoresheet"
    end
  end

  test 'should not get scoresheet as normal user' do
    with_users_signed_in @not_admins do |who|
      get scoresheet_course_url(@course)
      assert_response :redirect, "#{who} should not be able to get scoresheet"
    end
  end

  test 'should subscribe current_user to course' do
    with_users_signed_in @not_subscribed do |who, user|
      post subscribe_course_url(@course)
      assert @course.subscribed_members.include?(user), "#{who} should be able to subscribe"
    end
  end

  test 'subscribe should redirect to course' do
    with_users_signed_in @not_subscribed do |who|
      post subscribe_course_url(@course)
      assert_redirected_to @course, "#{who} should be redirected"
    end
  end

  test 'should get registration page with secret' do
    with_users_signed_in @not_subscribed do |who, user|
      %w[visible hidden].product(%w[open moderated closed]).each do |v, r|
        @course.update(visibility: v, registration: r)
        get registration_course_url(@course, @course.secret)
        assert_response :success, "#{who} should get registration page"
        # GET should not subscribe
        assert_not user.member_of?(@course), "#{who} should not be logged in"
      end
    end
  end

  test 'should not subscribe when already subscribed' do
    with_users_signed_in @course.users do |who|
      assert_difference('CourseMembership.count', 0, "#{who} should not be able to create a second membership") do
        post subscribe_course_url(@course)
      end
    end
  end

  test 'unsubscribed user should be able to resubscribe' do
    with_users_signed_in @unsubscribed do |who, user|
      assert_not user.member_of?(@course), "#{who} was already a member"
      post subscribe_course_url(@course)
      assert user.member_of?(@course), "#{who} should be a member"
    end
  end

  test 'visiting registration page when subscribed should redirect' do
    with_users_signed_in @subscribed do |who|
      get registration_course_url(@course, @course.secret)
      assert_redirected_to @course, "#{who} should be redirected"
    end
  end

  test 'should not subscribe to hidden course with invalid, empty or absent secret' do
    @course.update(visibility: 'hidden')
    with_users_signed_in @not_subscribed do |who, user|
      post subscribe_course_url(@course, secret: 'the cake is a lie')
      assert !user.member_of?(@course), "#{who} with invalid secret"

      post subscribe_course_url(@course, secret: '')
      assert !user.member_of?(@course), "#{who} with empty secret"

      post subscribe_course_url(@course)
      assert !user.member_of?(@course), "#{who} without secret"
    end
  end

  test 'should not subscribe to closed course' do
    @course.update(registration: 'closed')
    with_users_signed_in @not_subscribed do |who, user|
      @course.update(visibility: 'visible')
      post subscribe_course_url(@course)
      assert !user.member_of?(@course), "#{who} should not be subscribed"

      @course.update(visibility: 'hidden')
      post subscribe_course_url(@course, secret: @course.secret)
      assert !user.member_of?(@course), "#{who} should not be subscribed"
    end
  end

  test 'should not be on pending list with closed course' do
    @course.update(registration: 'closed')
    with_users_signed_in @externals do |who, user|
      @course.update(visibility: 'visible')
      post subscribe_course_url(@course)
      assert !@course.users.include?(user), "#{who} should not have a membership"

      @course.update(visibility: 'hidden')
      post subscribe_course_url(@course, secret: @course.secret)
      assert !@course.users.include?(user), "#{who} should not have a membership"
    end
  end

  test 'should be on pending list with moderated course' do
    @course.update(registration: 'moderated')
    with_users_signed_in @not_subscribed do |who, user|
      post subscribe_course_url(@course)
      assert @course.pending_members.include?(user), "#{who} should be pending"
    end
  end

  test 'should be on pending list with moderated and hidden course' do
    @course.update(registration: 'moderated', visibility: 'hidden')
    with_users_signed_in @not_subscribed do |who, user|
      post subscribe_course_url(@course, secret: @course.secret)
      assert @course.pending_members.include?(user), "#{who} should be pending"
    end
  end

  test 'externals should be able to see course' do
    with_users_signed_in @externals do |who|
      get course_url(@course)
      assert_response :success, "#{who} should be able to see course"
    end
  end

  test 'externals should not be able to see hidden course' do
    @course.update(visibility: 'hidden')
    with_users_signed_in @externals do |who|
      get course_url(@course)
      assert_redirected_to :root, "#{who} should not be able to see course"
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

  test 'everyone except admin & staff should not be able to promote or fire members' do
    student_admins = @admins.select(&:student?)
    group = @not_admins + student_admins
    with_users_signed_in group do |who|
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
    course = create :course
    admin = create :zeus
    course.administrating_members << admin
    sign_in admin

    post unsubscribe_course_url(@course)
    assert course.administrating_members.include?(admin)

    %w[student pending unsubscribed].each do |s|
      post update_membership_course_url(@course, user: admin, status: s)
      assert course.administrating_members.include?(admin)
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

  test 'unsubscribing user without solutions for course should delete  membership' do
    user = @students.first
    sign_in user

    post unsubscribe_course_url(@course)
    assert_not @course.users.include?(user)
  end

  test 'admins should be able to list members' do
    with_users_signed_in @admins do |who|
      get list_members_course_url(@course, format: :js)
      assert_response :success, "#{who} should be able to list members"
    end
  end

  test 'not-admins should not be able to list members' do
    with_users_signed_in @not_admins do |who|
      get list_members_course_url(@course, format: :js)
      assert_response :redirect, "#{who} should not be able to list members"
    end
  end
end
