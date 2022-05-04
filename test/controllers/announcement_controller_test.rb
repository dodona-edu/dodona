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

  def count_announcements(user)
    sign_in user
    get announcements_url, params: { unread: true }
    response.body.scan(/<tr class="announcement">/).size
  end

  test 'Mark as read should work' do
    student = create :student
    sign_in student
    assert_equal 1, count_announcements(student)
    post mark_as_read_announcement_url @instance, format: :js
    assert_equal 0, count_announcements(student)
  end

  test 'Students should only see announcements for their own institution' do
    create :announcement, institution_id: 1
    a = create :student, institution_id: 1
    b = create :student, institution_id: (create :institution).id
    assert_equal 2, count_announcements(a)
    assert_equal 1, count_announcements(b)
  end

  test 'Staff should only see announcements for their own institution' do
    create :announcement, institution_id: 1
    a = create :staff, institution_id: 1
    b = create :staff, institution_id: (create :institution).id
    assert_equal 2, count_announcements(a)
    assert_equal 1, count_announcements(b)
  end

  test 'Announcements should be filtered by user group' do
    create :announcement, user_group: :all_users
    student = create :student
    staff = create :staff
    zeus = create :zeus
    assert_equal 2, count_announcements(student)
    assert_equal 2, count_announcements(staff)
    assert_equal 2, count_announcements(zeus)

    create :announcement, user_group: :students
    assert_equal 3, count_announcements(student)
    assert_equal 2, count_announcements(staff)
    assert_equal 3, count_announcements(zeus)

    create :announcement, user_group: :staff
    assert_equal 3, count_announcements(student)
    assert_equal 3, count_announcements(staff)
    assert_equal 4, count_announcements(zeus)

    create :announcement, user_group: :zeus
    assert_equal 3, count_announcements(student)
    assert_equal 3, count_announcements(staff)
    assert_equal 5, count_announcements(zeus)
  end

  test 'only active announcements should be shown' do
    create :announcement, start_delivering_at: 1.day.ago
    student = create :student
    assert_equal 2, count_announcements(student)

    create :announcement, start_delivering_at: 1.day.from_now
    student = create :student
    assert_equal 2, count_announcements(student)

    create :announcement, stop_delivering_at: 1.day.from_now
    student = create :student
    assert_equal 3, count_announcements(student)

    create :announcement, stop_delivering_at: 1.day.ago
    student = create :student
    assert_equal 3, count_announcements(student)

    create :announcement, start_delivering_at: 1.day.ago, stop_delivering_at: 1.day.from_now
    student = create :student
    assert_equal 4, count_announcements(student)

    create :announcement, start_delivering_at: 2.days.ago, stop_delivering_at: 1.day.ago
    student = create :student
    assert_equal 4, count_announcements(student)

    create :announcement, start_delivering_at: 1.day.from_now, stop_delivering_at: 2.days.from_now
    student = create :student
    assert_equal 4, count_announcements(student)
  end
end
