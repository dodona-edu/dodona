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
#  series_count            :integer          default(0), not null
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

  test 'order by popularity should order by number of series using the activity' do
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
    # should count the same activity twice in the same course
    create_list :series, 5, course: c4, exercises: [e3]

    assert_equal [e3.id, e1.id, e2.id], Activity.order_by_popularity(:DESC).pluck(:id)
    assert_equal [e2.id, e1.id, e3.id], Activity.order_by_popularity(:ASC).pluck(:id)
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

  test 'should be able to filter by popularity' do
    Activity.delete_all
    unpopular1 = create :exercise
    unpopular2 = create :exercise
    neutral1 = create :exercise
    popular1 = create :exercise
    popular2 = create :exercise
    very_popular1 = create :exercise

    create :series, course: create(:course), exercises: [unpopular2]

    3.times { create :series, course: create(:course), exercises: [neutral1] }
    12.times { create :series, course: create(:course), exercises: [popular1] }
    50.times { create :series, course: create(:course), exercises: [popular2] }
    101.times { create :series, course: create(:course), exercises: [very_popular1] }

    assert_equal [unpopular1.id, unpopular2.id], Activity.by_popularity(:unpopular).order_by_popularity('ASC').pluck(:id)
    assert_equal [neutral1.id], Activity.by_popularity(:neutral).pluck(:id)
    assert_equal [popular1.id, popular2.id], Activity.by_popularity(:popular).order_by_popularity('ASC').pluck(:id)
    assert_equal [very_popular1.id], Activity.by_popularity(:very_popular).pluck(:id)
  end

  test 'should be able to filter by popularity with multiple values' do
    Activity.delete_all
    unpopular1 = create :exercise
    unpopular2 = create :exercise
    neutral1 = create :exercise
    popular1 = create :exercise
    popular2 = create :exercise
    very_popular1 = create :exercise

    create :series, course: create(:course), exercises: [unpopular2]

    3.times { create :series, course: create(:course), exercises: [neutral1] }
    12.times { create :series, course: create(:course), exercises: [popular1] }
    50.times { create :series, course: create(:course), exercises: [popular2] }
    101.times { create :series, course: create(:course), exercises: [very_popular1] }

    assert_equal [unpopular1.id, unpopular2.id, popular1.id, popular2.id], Activity.by_popularities(%i[unpopular popular]).order_by_popularity('ASC').pluck(:id)
    assert_equal [neutral1.id, very_popular1.id], Activity.by_popularities(%i[neutral very_popular]).order_by_popularity('ASC').pluck(:id)
  end

  test 'repository mine should filter correctly' do
    repository = create :repository, :git_stubbed
    user = create :staff
    repository.admins << user
    exercise = create :exercise, repository: repository
    content_page = create :content_page, repository: repository

    assert_includes Activity.repository_scope(scope: :mine, user: user), exercise
    assert_includes Activity.repository_scope(scope: :mine, user: user), content_page
    assert_not_includes Activity.repository_scope(scope: :mine, user: create(:user)), exercise
    assert_not_includes Activity.repository_scope(scope: :mine, user: create(:user)), content_page

    course = create :course
    repository = create :repository, :git_stubbed
    exercise = create :exercise, repository: repository
    content_page = create :content_page, repository: repository
    repository.allowed_courses = [course]

    assert_includes Activity.repository_scope(scope: :mine, user: user, course: course), exercise
    assert_includes Activity.repository_scope(scope: :mine, user: user, course: course), content_page
    assert_not_includes Activity.repository_scope(scope: :mine, user: user, course: create(:course)), exercise
    assert_not_includes Activity.repository_scope(scope: :mine, user: user, course: create(:course)), content_page
  end

  test 'repository owned by institution scope should filter correctly' do
    repository = create :repository, :git_stubbed
    institution = create :institution
    user = create :staff, institution: institution
    repository.admins << user
    exercise = create :exercise, repository: repository
    content_page = create :content_page, repository: repository

    assert_includes Activity.repository_scope(scope: :my_institution, user: user), exercise
    assert_includes Activity.repository_scope(scope: :my_institution, user: user), content_page
    assert_not_includes Activity.repository_scope(scope: :my_institution, user: create(:user)), exercise
    assert_not_includes Activity.repository_scope(scope: :my_institution, user: create(:user)), content_page
  end

  test 'repository featured scope should filter correctly' do
    repository = create :repository, :git_stubbed
    exercise = create :exercise, repository: repository
    content_page = create :content_page, repository: repository
    repository.update(featured: true)

    assert_includes Activity.repository_scope(scope: :featured), exercise
    assert_includes Activity.repository_scope(scope: :featured), content_page
    repository.update(featured: false)

    assert_not_includes Activity.repository_scope(scope: :featured), exercise
    assert_not_includes Activity.repository_scope(scope: :featured), content_page
  end

  test 'repository scope my institution should return nothing if user has no institution or is nil' do
    assert_not_empty Activity.all
    assert_empty Activity.repository_scope(scope: :my_institution, user: nil)
    assert_empty Activity.repository_scope(scope: :my_institution, user: create(:user, institution_id: nil))
  end
end
