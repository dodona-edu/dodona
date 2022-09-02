# == Schema Information
#
# Table name: courses
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  year              :string(255)
#  secret            :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  description       :text(16777215)
#  visibility        :integer
#  registration      :integer
#  teacher           :string(255)
#  institution_id    :bigint
#  search            :string(4096)
#  moderated         :boolean          default(FALSE), not null
#  enabled_questions :boolean          default(TRUE), not null
#  featured          :boolean          default(FALSE), not null
#

require 'test_helper'

class CourseTest < ActiveSupport::TestCase
  test 'factory should create course' do
    course = create :course
    assert_not_nil course
    assert_not course.secret.blank?
  end

  test 'create course with emoji' do
    name = 'Programming 🧑‍💻'
    course = create :course, name: name
    assert_not_nil course
    assert_equal course.name, name
  end

  test 'course formatted year should not have spaces' do
    course = build :course, year: '2017 - 2018'
    assert_equal '2017–2018', course.formatted_year
  end

  test 'course formatted attribution should only have a dot with teacher and institution' do
    course = build :course, teacher: ''
    assert_equal '', course.formatted_attribution

    course = build :course, teacher: 'teach'
    assert_equal 'teach', course.formatted_attribution

    course = build :course, teacher: '', institution: (build :institution, short_name: 'sn', name: '')
    assert_equal '', course.formatted_attribution

    course = build :course, teacher: 'teach', institution: (build :institution, short_name: 'sn', name: '')
    assert_equal 'teach', course.formatted_attribution

    course = build :course, teacher: '', institution: (build :institution, short_name: 'sn', name: 'inst')
    assert_equal 'inst', course.formatted_attribution

    course = build :course, teacher: 'teach', institution: (build :institution, short_name: 'sn', name: 'inst')
    assert_equal 'teach · inst', course.formatted_attribution
  end

  test 'hidden course should always require secret' do
    course = build :course, institution: (build :institution), visibility: :hidden
    user1 = build :user, institution: nil
    user2 = build :user, institution: course.institution
    user3 = build :user, institution: (build :institution)

    assert course.secret_required?
    assert course.secret_required?(user1)
    assert course.secret_required?(user2)
    assert course.secret_required?(user3)
  end

  test 'visible_for_institution course should not require secret for user of institution' do
    course = build :course, institution: (build :institution), visibility: :visible_for_institution
    user1 = build :user, institution: nil
    user2 = build :user, institution: course.institution
    user3 = build :user, institution: (build :institution)

    assert course.secret_required?
    assert course.secret_required?(user1)
    assert_not course.secret_required?(user2)
    assert course.secret_required?(user3)
  end

  test 'visible_for_all course should never require secret' do
    course = build :course, institution: (build :institution), visibility: :visible_for_all
    user1 = build :user, institution: nil
    user2 = build :user, institution: course.institution
    user3 = build :user, institution: (build :institution)

    assert_not course.secret_required?
    assert_not course.secret_required?(user1)
    assert_not course.secret_required?(user2)
    assert_not course.secret_required?(user3)
  end

  test 'correct solutions should be updated for submission in course' do
    course = courses(:course1)
    series = create :series, course: course, activity_count: 1
    user = users(:student)

    assert_equal 0, course.correct_solutions

    create :wrong_submission,
           course: course,
           exercise: series.exercises[0],
           user: user

    assert_equal 0, course.correct_solutions

    create :correct_submission,
           course: course,
           exercise: series.exercises[0],
           user: user

    assert_equal 1, course.correct_solutions
  end

  test 'correct solutions should not be updated for submission outside course' do
    course = courses(:course1)
    series = create :series, course: course, activity_count: 1
    user = users(:student)

    assert_equal 0, course.correct_solutions

    create :wrong_submission,
           exercise: series.exercises[0],
           user: user

    assert_equal 0, course.correct_solutions

    create :correct_submission,
           exercise: series.exercises[0],
           user: user

    assert_equal 0, course.correct_solutions
  end

  test 'course scoresheet should be correct' do
    course = courses(:course1)
    create_list :series, 2,
                course: course,
                exercise_count: 2,
                deadline: Time.current
    content_pages = create_list :content_page, 2
    SeriesMembership.create(series: course.series.first, activity: content_pages.first)
    SeriesMembership.create(series: course.series.second, activity: content_pages.second)
    users = create_list(:user, 6, courses: [course])

    expected_started = Hash.new 0
    expected_accepted = Hash.new 0
    course.series.each do |series|
      deadline = series.deadline
      series.exercises.map do |exercise|
        6.times do |i|
          u = users[i]
          case i
          when 0 # Wrong submission before deadline
            create :wrong_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline - 2.minutes),
                   course: course
            expected_started[[u.id, series.id]] += 1
          when 1 # Wrong, then correct submission before deadline
            create :correct_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline - 2.minutes),
                   course: course
            create :correct_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline - 1.minute),
                   course: course
            expected_started[[u.id, series.id]] += 1
            expected_accepted[[u.id, series.id]] += 1
          when 2 # Wrong submission after deadline
            create :wrong_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline + 2.minutes),
                   course: course
          when 3 # Correct submission after deadline
            create :correct_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline + 2.minutes),
                   course: course
          when 4 # Correct submission before deadline not in course
            create :correct_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline - 2.minutes)
          when 5 # Correct submission after deadline not in course
            create :correct_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline + 2.minutes)
          end
        end
      end
      series.content_pages.map do |cp|
        6.times do |i|
          u = users[i]
          if i.even?
            create :activity_read_state, activity: cp, user: u, course: course, created_at: (deadline - 2.minutes)
            expected_started[[u.id, series.id]] += 1
            expected_accepted[[u.id, series.id]] += 1
          else
            create :activity_read_state, activity: cp, user: u, course: course, created_at: (deadline + 2.minutes)
          end
        end
      end
    end

    scoresheet = course.scoresheet
    # All users are included in the scoresheet.
    assert_equal users.to_set, scoresheet[:users].to_set
    # All series are included in the scoresheet.
    assert_equal course.series.to_set, scoresheet[:series].to_set
    # All series and users are counted.
    assert_equal course.series.count * users.count, scoresheet[:hash].count
    # Correct series are counted.
    assert_equal scoresheet[:hash].keys.map { |k| k[1] }.to_set, scoresheet[:series].map(&:id).to_set
    # Correct users are counted.
    assert_equal scoresheet[:hash].keys.map(&:first).to_set, users.map(&:id).to_set
    # Counts are correct.
    scoresheet[:hash].each do |key, counts|
      assert_equal expected_accepted[key], counts[:accepted]
      assert_equal expected_started[key], counts[:started]
    end
  end

  test 'destroying course does not destroy submissions' do
    course = create :course, series_count: 1, exercises_per_series: 1, submissions_per_exercise: 1
    assert_difference 'Submission.count', 0 do
      assert course.destroy
    end
  end

  test 'destroying course should move submission files' do
    course = create :course, series_count: 1, exercises_per_series: 1, submissions_per_exercise: 1
    submission = Submission.first
    code = submission.code
    assert course.destroy
    assert_equal code, submission.reload.code
  end

  test 'all_activities_accessible? should be correct' do
    course = create :course, series_count: 1, exercises_per_series: 0
    ex = create :exercise, access: :public
    course.series.first.exercises << ex
    assert course.all_activities_accessible?
    ex.update(access: :private)
    assert_not course.all_activities_accessible?
    course.usable_repositories << ex.repository
    assert course.all_activities_accessible?
  end

  test 'can_register scope should always contain own courses' do
    i = create :institution
    [create(:institution), i, nil].each do |institution|
      u = create :user, institution: institution
      CourseMembership.statuses.each do |s|
        Course.registrations.each do |r|
          c = create :course, registration: r[1], institution: i
          CourseMembership.create user: u, course: c, status: s[1]
        end
      end
      assert_equal u.subscribed_courses.count, u.subscribed_courses.can_register(u).count
    end
  end

  test 'can_register should only return course if the user can register for it' do
    i = create :institution
    Course.registrations.each do |r|
      create :course, registration: r[1], institution: i
    end
    [create(:institution), i, nil].each do |institution|
      u = create :user, institution: institution
      Course.all.each do |c|
        assert_equal c.open_for_user?(u), Course.can_register(u).exists?(c.id)
      end
    end
  end
end
