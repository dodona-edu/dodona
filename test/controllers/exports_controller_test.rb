require 'test_helper'

class ExportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    stub_all_activities!
    @course = courses(:course1)
    @students = [users(:student), users(:staff), create(:student)]
    @course.enrolled_members.concat(@students)
    @series = create :series,
                     :with_submissions,
                     exercise_count: 2,
                     exercise_submission_count: 0,
                     exercise_submission_users: @students,
                     course: @course,
                     deadline: Time.current
    create :wrong_submission, exercise: @series.exercises.first, user: @students.first, course: @course
    create :wrong_submission, exercise: @series.exercises.first, user: @students.first, course: @course
    create :wrong_submission, exercise: @series.exercises.second, user: @students.first, course: @course
    create :correct_submission, exercise: @series.exercises.second, user: @students.first, course: @course
    create :correct_submission, exercise: @series.exercises.first, user: @students.second, course: @course
    create :correct_submission, exercise: @series.exercises.first, user: @students.third, course: @course
    # make accessing all database-objects easier, no need for querying
    @data = { course: @course, users: @students, series: @series, exercises: @series.exercises, deadline: @series.deadline }
    sign_in users(:zeus)
  end

  test 'should retrieve download solutions wizard page' do
    get series_exports_path(@series)

    assert_response :success
  end

  test 'should download only last submissions' do
    post series_exports_path(@series), params: { all: true, only_last_submission: true, with_info: true, format: :json }

    assert_response :success
    count = @students.map { |u| @series.exercises.map { |e| e.last_submission(u, @series) } }.flatten.compact_blank.count

    assert_zip ActiveStorage::Blob.last.download, with_info: true, solution_count: count, data: @data
  end

  test 'should be grouped by user' do
    post series_exports_path(@series), params: { all: true, group_by: 'user', format: :json }

    assert_response :success
    assert_zip ActiveStorage::Blob.last.download, group_by: 'user', data: @data
  end

  test 'should be grouped by exercise' do
    post series_exports_path(@series), params: { all: true, group_by: 'exercise', format: :json }

    assert_response :success
    assert_zip ActiveStorage::Blob.last.download, group_by: 'exercise', data: @data
  end

  test 'should retrieve all submissions' do
    post series_exports_path(@series), params: { all: true, format: :json }

    assert_response :success
    assert_zip ActiveStorage::Blob.last.download, solution_count: Submission.count, data: @data
  end

  test 'all students should be present in the zip' do
    @new_student = create :student
    @course.enrolled_members.push(@new_student)
    @data[:users].push(@new_student)
    zip_submission_count = @data[:users].map do |u|
      @data[:exercises].map do |ex|
        subs = ex.submissions.of_user(u).in_course(@series.course)
        subs = [1] if subs.empty?
        subs
      end
    end.flatten.length

    post series_exports_path(@series), params: { all: true, filter_students: 'all', format: :json }

    assert_response :success
    assert_zip ActiveStorage::Blob.last.download, solution_count: zip_submission_count, data: @data
  end

  test 'zip should only contain submissions before deadline' do
    @series.update(deadline: 1.year.ago)
    post series_exports_path(@series), params: { all: true, deadline: true, format: :json }

    assert_response :success
    zip_submission_count = @series.exercises.map { |ex| ex.submissions.before_deadline(@series.deadline) }.flatten.length

    assert_zip ActiveStorage::Blob.last.download, solution_count: zip_submission_count, data: @data

    @series.update(deadline: 2.years.from_now)
    post series_exports_path(@series), params: { all: true, deadline: true, format: :json }

    assert_response :success
    zip_submission_count = @series.exercises.map { |ex| ex.submissions.before_deadline(@series.deadline) }.flatten.length

    assert_zip ActiveStorage::Blob.last.download, solution_count: zip_submission_count, data: @data
  end

  test 'should only download from specific exercises' do
    sample_exercises = @series.exercises.sample(3)
    post series_exports_path(@series), params: { selected_ids: sample_exercises.map(&:id), filter_students: 'all', format: :json }
    zip_submission_count = @data[:users].map do |u|
      sample_exercises.map do |ex|
        subs = ex.submissions.of_user(u).in_course(@series.course)
        subs = [1] if subs.empty?
        subs
      end
    end.flatten.length

    assert_zip ActiveStorage::Blob.last.download, solution_count: zip_submission_count, data: @data
  end

  test 'all options should be able to be used simultaneously' do
    @series.update(deadline: Time.current)
    sample_exercises = @series.exercises.sample(3)
    options = { selected_ids: sample_exercises.map(&:id),
                filter_students: 'all',
                only_last_submission: true,
                deadline: @series.deadline,
                course: @series.course,
                with_info: true,
                group_by: 'exercise',
                data: @data,
                format: :json }
    options[:solution_count] = @data[:users].map do |u|
      sample_exercises.map do |ex|
        ex.submissions.of_user(u).in_course(@series.course).before_deadline(@series.deadline).limit(1).first
      end
    end.flatten.length
    post series_exports_path(@series), params: options

    assert_zip ActiveStorage::Blob.last.download, options
  end

  test 'should download all submissions from course' do
    create :series, :with_submissions, course: @course, exercise_submission_users: @students
    options = {
      only_last_submission: false,
      data: @data,
      solution_count: Submission.all.in_course(@course).count,
      all: true,
      format: :json
    }
    post courses_exports_path(@course), params: options

    assert_response :success
    options[:group_by] = 'series'

    assert_zip ActiveStorage::Blob.last.download, options
  end

  test 'should not contain submissions from other courses' do
    s1 = create :series, :with_submissions, course: @course, exercise_submission_users: @students
    s2 = create :series, course: (create :course)
    s2.exercises = s1.exercises
    s2.course.users = s1.course.users
    create :submission, exercise: s2.exercises.first, course: s2.course, user: @students.first
    options = {
      only_last_submission: false,
      data: @data,
      solution_count: Submission.all.in_course(@course).count,
      all: true,
      format: :json
    }
    post courses_exports_path(@course), params: options

    assert_response :success
    options[:group_by] = 'series'

    assert_zip ActiveStorage::Blob.last.download, options
  end

  test 'should not contain submissions from other courses, especially when rights are not there' do
    s1 = create :series, :with_submissions, course: @course, exercise_submission_users: @students
    s2 = create :series, course: (create :course)
    s2.exercises = s1.exercises
    s2.course.users = s1.course.users
    u = create :user
    s1.course.administrating_members << u
    create :submission, exercise: s2.exercises.first, course: s2.course, user: @students.first
    options = {
      only_last_submission: false,
      data: @data,
      solution_count: Submission.all.in_course(@course).count,
      all: true,
      format: :json
    }
    sign_in u
    post courses_exports_path(@course), params: options

    assert_response :success
    options[:group_by] = 'series'

    assert_zip ActiveStorage::Blob.last.download, options
  end

  test 'should download one submission per exercise from each series from course' do
    options = {
      only_last_submission: true,
      deadline: true,
      group_by: 'user',
      filter_students: 'all',
      with_info: true,
      data: @data,
      all: true,
      solution_count: @course.users.count * @course.series.map(&:exercises).flatten.count,
      format: :json
    }
    post courses_exports_path(@course), params: options

    assert_response :success
    assert_zip ActiveStorage::Blob.last.download, options
  end

  test 'should download all existing submissions from course and include all students in zip' do
    options = {
      group_by: 'exercise',
      filter_students: 'all',
      data: @data,
      all: true,
      format: :json
    }
    options[:solution_count] = @course.series.map do |series|
      @course.users.map do |user|
        series.exercises.map do |exercise|
          [exercise.submissions.of_user(user).in_course(@course).count, 1].max
        end.sum
      end.sum
    end.sum
    post courses_exports_path(@course), params: options
    options[:group_by] = 'series'

    assert_zip ActiveStorage::Blob.last.download, options
  end

  test 'should download all existing submissions from course but only include students with at least one correct submission' do
    options = {
      group_by: 'exercise',
      filter_students: 'correct',
      data: @data,
      all: true,
      format: :json
    }
    options[:solution_count] = @course.series.map do |series|
      @course.users.map do |user|
        series.exercises.map do |exercise|
          if exercise.submissions.of_user(user).in_course(@course).correct.any?
            [exercise.submissions.of_user(user).in_course(@course).count, 1].max
          else
            0
          end
        end.sum
      end.sum
    end.sum
    post courses_exports_path(@course), params: options
    options[:group_by] = 'series'

    assert_zip ActiveStorage::Blob.last.download, options
  end

  test 'should download all submissions of the user' do
    student = @students[0]
    options = {
      data: @data,
      all: true,
      solution_count: Submission.all.of_user(student).count,
      format: :json
    }
    @data[:user] = student
    post users_exports_path(student), params: options
    options[:group_by] = 'course'

    assert_zip ActiveStorage::Blob.last.download, options
  end

  test 'should not be able to download submissions of other user' do
    sign_in @students[0]
    other_student = @students[1]
    options = {
      data: @data,
      all: true,
      solution_count: Submission.all.of_user(other_student).count,
      format: :json
    }
    post users_exports_path(other_student, format: :json), params: options

    assert_response :forbidden

    sign_in create(:staff, administrating_courses: [@course])
    post users_exports_path(other_student, format: :json), params: options

    assert_response :forbidden
  end

  test 'should be able to export course if course member' do
    sign_in @students[0]

    post courses_exports_path(@course, user_id: @students[0].id, format: :json)

    assert_response :success
  end

  test 'should not be able to export course if not course member' do
    u = create :user
    sign_in u

    post courses_exports_path(@course, user_id: u.id, format: :json)

    assert_response :forbidden
  end

  test 'should not be able to export full course if not course admin' do
    sign_in @students[0]

    post courses_exports_path(@course, format: :json)

    assert_response :forbidden
  end

  test 'should be able to export series if course member' do
    sign_in @students[0]

    post series_exports_path(@course.series.first, user_id: @students[0].id, format: :json)

    assert_response :success
  end

  test 'should not be able to export series if not course member' do
    u = create :user
    sign_in u

    post series_exports_path(@course.series.first, user_id: u.id, format: :json)

    assert_response :forbidden
  end

  test 'should not be able to export full series if not course admin' do
    sign_in @students[0]

    post series_exports_path(@course.series.first, format: :json)

    assert_response :forbidden
  end
end
