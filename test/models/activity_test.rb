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

  test 'should order by name' do
    Activity.delete_all
    e1 = create :exercise, name_nl: 'foo', name_en: 'baz'
    e2 = create :exercise, name_nl: 'bar', name_en: 'bar'
    e3 = create :exercise, name_nl: 'baz', name_en: 'foo'
    I18n.with_locale(:nl) do
      assert_equal [e1.id, e3.id, e2.id], Activity.order_by_name(:DESC).pluck(:id)
      assert_equal [e2.id, e3.id, e1.id], Activity.order_by_name(:ASC).pluck(:id)
    end
    I18n.with_locale(:en) do
      assert_equal [e3.id, e1.id, e2.id], Activity.order_by_name(:DESC).pluck(:id)
      assert_equal [e2.id, e1.id, e3.id], Activity.order_by_name(:ASC).pluck(:id)
    end
  end

  test 'order by name should order nils last' do
    Activity.delete_all
    e1 = create :exercise, name_nl: 'foo', name_en: 'foo'
    e2 = create :exercise, name_nl: nil, name_en: 'test'
    e3 = create :exercise, name_nl: 'test', name_en: nil
    I18n.with_locale(:nl) do
      assert_equal [e3.id, e1.id, e2.id], Activity.order_by_name(:DESC).pluck(:id)
      assert_equal [e1.id, e3.id, e2.id], Activity.order_by_name(:ASC).pluck(:id)
    end
    I18n.with_locale(:en) do
      assert_equal [e2.id, e1.id, e3.id], Activity.order_by_name(:DESC).pluck(:id)
      assert_equal [e1.id, e2.id, e3.id], Activity.order_by_name(:ASC).pluck(:id)
    end
  end

  test 'order by popularity should order by number of courses using the activity' do
    Activity.delete_all
    e1 = create :exercise, name_nl: 'foo', name_en: 'foo'
    e2 = create :exercise, name_nl: 'bar', name_en: 'bar'
    e3 = create :exercise, name_nl: 'baz', name_en: 'baz'
    c1 = create :course
    c2 = create :course
    c3 = create :course
    c4 = create :course
    create :series, course: c1, exercises: [e1]
    create :series, course: c2, exercises: [e1]
    create :series, course: c3, exercises: [e1, e2]
    create :series, course: c4, exercises: [e2, e3]
    # should not count the same activity twice in the same course
    5.times { create :series, course: c4, exercises: [e3] }
    assert_equal [e1.id, e2.id, e3.id], Activity.order_by_popularity(:DESC).pluck(:id)
    assert_equal [e3.id, e2.id, e1.id], Activity.order_by_popularity(:ASC).pluck(:id)
  end

  test 'popularity should return the correct enum value' do
    e1 = create :exercise
    assert_equal :unpopular, e1.popularity
    rand(0..2).times do
      c1 = create :course
      create :series, course: c1, exercises: [e1]
    end

    e2 = create :exercise
    rand(3..9).times do
      c3 = create :course
      create :series, course: c3, exercises: [e2]
    end
    assert_equal :neutral, e2.reload.popularity

    e3 = create :exercise
    rand(12..50).times do
      c4 = create :course
      create :series, course: c4, exercises: [e3]
    end
    assert_equal :popular, e3.reload.popularity

    e4 = create :exercise
    101.times do
      c5 = create :course
      create :series, course: c5, exercises: [e4]
    end
    assert_equal :very_popular, e4.reload.popularity
  end
end
