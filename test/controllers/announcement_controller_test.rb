require 'test_helper'

class AnnouncementControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Announcement, attrs: %i[text_nl text_en user_group institution_id style]

  setup do
    sign_in create(:zeus, institution: institutions(:ugent))
    @instance = create :announcement
  end

  test_crud_actions only: %i[new create destroy index edit update], except: %i[destroy_redirect create_redirect update_redirect]

  test 'create should redirect to index' do
    create_request_expect
    assert_redirected_to announcements_url
  end

  def announcement?(user = nil)
    sign_in user if user.present?
    get root_url
    sign_out user if user.present?
    response.body.scan(/class="announcement/).size == 1
  end

  test 'Mark as read should work' do
    student = create :student
    assert announcement? student
    sign_in student
    post mark_as_read_announcement_url @instance, format: :js
    assert_not announcement? student
  end

  test 'Students should only see announcements for their own institution' do
    @instance.update institution_id: 1
    a = create :student, institution_id: 1
    b = create :student, institution_id: (create :institution).id
    assert announcement? a
    assert_not announcement? b
  end

  test 'Staff should only see announcements for their own institution' do
    @instance.update institution_id: 1
    a = create :staff, institution_id: 1
    b = create :staff, institution_id: (create :institution).id
    assert announcement? a
    assert_not announcement? b
  end

  test 'Announcements should be filtered by user group' do
    student = create :student
    staff = create :staff
    zeus = create :zeus

    @instance.update user_group: :everyone
    assert announcement? student
    assert announcement? staff
    assert announcement? zeus
    assert announcement?

    @instance.update user_group: :all_users
    assert announcement? student
    assert announcement? staff
    assert announcement? zeus
    assert_not announcement?

    @instance.update user_group: :students
    assert announcement? student
    assert_not announcement? staff
    assert announcement? zeus
    assert_not announcement?

    @instance.update user_group: :staff
    assert_not announcement? student
    assert announcement? staff
    assert announcement? zeus
    assert_not announcement?

    @instance.update user_group: :zeus
    assert_not announcement? student
    assert_not announcement? staff
    assert announcement? zeus
    assert_not announcement?
  end

  test 'only active announcements should be shown' do
    student = create :student
    @instance.update start_delivering_at: 1.day.ago
    assert announcement? student

    @instance.update start_delivering_at: 1.day.from_now
    assert_not announcement? student

    @instance.update start_delivering_at: nil
    @instance.update stop_delivering_at: 1.day.from_now
    assert announcement? student

    @instance.update stop_delivering_at: 1.day.ago
    assert_not announcement? student

    @instance.update start_delivering_at: 1.day.ago, stop_delivering_at: 1.day.from_now
    assert announcement? student

    @instance.update start_delivering_at: 2.days.ago, stop_delivering_at: 1.day.ago
    assert_not announcement? student

    @instance.update start_delivering_at: 1.day.from_now, stop_delivering_at: 2.days.from_now
    assert_not announcement? student
  end

  test 'Reset read states on update should work' do
    5.times do
      student = create :student
      sign_in student
      post mark_as_read_announcement_url @instance, format: :js
    end
    assert_equal 5, @instance.announcement_views.count
    sign_in create :zeus
    put announcement_url @instance, announcement: { text_nl: 'a', text_en: 'b' }
    assert_equal 5, @instance.announcement_views.count
    put announcement_url @instance, announcement: { text_nl: 'a', text_en: 'b' }, reset_announcement_views: true
    assert_equal 0, @instance.announcement_views.count
  end
end
