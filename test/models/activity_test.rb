# == Schema Information
#
# Table name: activities
#
#  id                      :integer          not null, primary key
#  name_nl                 :string(255)
#  name_en                 :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  path                    :string(255)
#  description_format      :string(255)
#  repository_id           :integer
#  judge_id                :integer
#  status                  :integer          default("ok")
#  access                  :integer          default("public"), not null
#  programming_language_id :bigint
#  search                  :string(4096)
#  access_token            :string(16)       not null
#  repository_token        :string(64)       not null
#  allow_unsafe            :boolean          default(FALSE), not null
#  type                    :string(255)      default("Exercise"), not null
#  description_nl_present  :boolean          default(FALSE)
#  description_en_present  :boolean          default(FALSE)
#

require 'test_helper'

class ActivityTest < ActiveSupport::TestCase
  test 'factory should create exercise' do
    exercise = create :exercise
    assert_not_nil exercise
  end

  test 'users_read' do
    e = exercises(:python_exercise)
    course1 = create :course
    create :series, course: course1, exercises: [e]
    course2 = create :course
    create :series, course: course2, exercises: [e]

    user_c1 = create :user, courses: [course1]

    assert_equal 0, e.users_read
    assert_equal 0, e.users_read(course: course1)
    assert_equal 0, e.users_read(course: course2)

    # Create activity read state for unscoped exercise.
    create :activity_read_state, user: user_c1, activity: e
    assert_equal 1, e.users_read
    assert_equal 0, e.users_read(course: course1)
    assert_equal 0, e.users_read(course: course2)

    # Create activity read state for course 1.
    create :activity_read_state, user: user_c1, course: course1, activity: e
    assert_equal 1, e.users_read
    assert_equal 1, e.users_read(course: course1)
    assert_equal 0, e.users_read(course: course2)
  end

  test 'converting an exercise to a content page and back should retain submissions' do
    exercise = create :exercise, submission_count: 2
    exercise_id = exercise.id
    assert_equal 2, exercise.submissions.count

    # Convert the Exercise to a ContentPage.
    exercise.update(type: ContentPage.name)
    exercise.save

    # Fetch the ContentPage from the database.
    content_page_activity = Activity.find(exercise_id)
    assert_instance_of ContentPage, content_page_activity

    # Convert the ContentPage back to an Exercise.
    content_page_activity.update(type: Exercise.name)
    content_page_activity.save

    # Fetch the Exercise from the database.
    exercise_activity = Activity.find(exercise_id)
    assert_instance_of Exercise, exercise_activity
    assert_equal 2, exercise_activity.submissions.count
  end

  test 'numbered_name should work' do
    e = create :exercise, name_nl: 'foo', name_en: 'foo'
    assert_equal 'foo', e.numbered_name(nil)
    s = create :series
    assert_equal 'foo', e.numbered_name(s)
    s.update(activity_numbers_enabled: true)
    assert_equal 'foo', e.numbered_name(s)
    m1 = SeriesMembership.create series: s, activity: e
    assert_equal '1. foo', e.numbered_name(s)
    m2 = SeriesMembership.create series: s, activity: create(:exercise)
    c = create :content_page, name_nl: 'bar', name_en: 'bar'
    m3 = SeriesMembership.create series: s, activity: c
    m4 = SeriesMembership.create series: s, activity: create(:exercise)
    assert_equal '1. foo', e.numbered_name(s)
    assert_equal '3. bar', c.numbered_name(s)
    m2.update(order: 0)
    m3.update(order: 1)
    m4.update(order: 2)
    m1.update(order: 3)
    assert_equal '4. foo', e.numbered_name(s)
    assert_equal '2. bar', c.numbered_name(s)
    s.update(activity_numbers_enabled: false)
    assert_equal 'foo', e.numbered_name(s)
    assert_equal 'bar', c.numbered_name(s)
  end
end
