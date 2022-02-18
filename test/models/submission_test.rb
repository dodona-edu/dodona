# == Schema Information
#
# Table name: submissions
#
#  id          :integer          not null, primary key
#  exercise_id :integer
#  user_id     :integer
#  summary     :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  status      :integer
#  accepted    :boolean          default(FALSE)
#  course_id   :integer
#  fs_key      :string(24)
#

require 'test_helper'

class SubmissionTest < ActiveSupport::TestCase
  FILE_LOCATION = Rails.root.join('test/files/output.json')

  test 'factory should create submission' do
    assert_not_nil create(:submission)
  end

  test 'submission with content_page as exercise is not valid' do
    submission = build :submission
    content_page = build :content_page

    assert_raises ActiveRecord::AssociationTypeMismatch do
      submission.exercise = content_page
    end

    assert_not submission.update(exercise_id: content_page.id)
  end

  test 'should not create job for submission which is already queued' do
    submission = nil
    assert_jobs_enqueued(1) do
      submission = create :submission, evaluate: true
    end
    assert_jobs_enqueued(0) do
      submission.evaluate_delayed
    end
  end

  test 'submissions should be rate limited for a user' do
    user = users(:student)
    create :submission, user: user
    submission = build :submission, :rate_limited, user: user
    assert_not submission.valid?

    later = 10.seconds.from_now

    Time.stubs(:now).returns(later)

    later_submission = build :submission, :rate_limited, user: user
    assert later_submission.valid?, 'should be able to create submission after waiting'
  end

  test 'submissions should not be rate limited for different users' do
    user = users(:student)
    other = users(:staff)
    create :submission, user: user
    submission = build :submission, :rate_limited, user: other
    assert submission.valid?
  end

  test 'submissions that are too long should be rejected' do
    submission = build :submission, code: Random.new.alphanumeric(64.kilobytes)
    assert_not submission.valid?
  end

  test 'submissions that are short enough should not be rejected' do
    submission = build :submission, code: Random.new.alphanumeric(64.kilobytes - 1)
    assert submission.valid?
  end

  test 'new submissions should have code on the filesystem' do
    code = Random.new.alphanumeric(100)
    submission = build :submission, code: code
    assert_equal code, File.read(File.join(submission.fs_path, Submission::CODE_FILENAME))
  end

  test 'new submissions should have result on the filesystem' do
    result = Random.new.alphanumeric(100)
    submission = build :submission, result: result
    assert_equal result, ActiveSupport::Gzip.decompress(File.read(File.join(submission.fs_path, Submission::RESULT_FILENAME)))
  end

  test 'safe_result should remove staff tabs for students' do
    json = FILE_LOCATION.read
    submission = build :submission, result: json, status: :correct
    user = users(:student)
    result = JSON.parse(submission.safe_result(user), symbolize_names: true)
    assert_equal 1, result[:groups].count
  end

  test 'safe_result should remove zeus tabs for staff' do
    json = FILE_LOCATION.read
    submission = build :submission, result: json, status: :correct
    user = users(:staff)
    result = JSON.parse(submission.safe_result(user), symbolize_names: true)
    assert_equal 2, result[:groups].count
  end

  test 'safe_result should display all tabs to zeus' do
    json = FILE_LOCATION.read
    submission = build :submission, result: json, status: :correct
    user = users(:zeus)
    result = JSON.parse(submission.safe_result(user), symbolize_names: true)
    assert_equal 3, result[:groups].count
  end

  test 'safe_result should remove staff and zeus messages for students' do
    json = FILE_LOCATION.read
    submission = build :submission, result: json, status: :correct
    user = users(:student)
    result = JSON.parse(submission.safe_result(user), symbolize_names: true)
    assert_equal 2, result[:messages].count
    assert_equal 2, result[:groups][0][:messages].count
    assert_equal 2, result[:groups][0][:groups][0][:messages].count
    assert_equal 2, result[:groups][0][:groups][0][:groups][0][:messages].count
    assert_equal 2, result[:groups][0][:groups][0][:groups][0][:tests][0][:messages].count
  end

  test 'safe_result should remove zeus message for staff' do
    json = FILE_LOCATION.read
    submission = build :submission, result: json, status: :correct
    user = users(:staff)
    result = JSON.parse(submission.safe_result(user), symbolize_names: true)
    assert_equal 2, result[:groups].count
    assert_equal 3, result[:messages].count
    assert_equal 3, result[:groups][0][:messages].count
    assert_equal 3, result[:groups][0][:groups][0][:messages].count
    assert_equal 3, result[:groups][0][:groups][0][:groups][0][:messages].count
    assert_equal 3, result[:groups][0][:groups][0][:groups][0][:tests][0][:messages].count
  end

  test 'transferring to another course should move the underlying result and code' do
    submission = create :submission, result: 'result', code: 'code', status: :correct
    path = submission.fs_path
    new_course = create :course
    submission.update(course: new_course)
    assert_equal 'result', submission.result
    assert_equal 'code', submission.code
    assert File.exist?(submission.fs_path)
    assert_not File.exist?(path)
  end

  test 'transferring to another exercise should move the underlying result and code' do
    submission = create :submission, result: 'result', code: 'code', status: :correct
    path = submission.fs_path
    new_exercise = create :exercise
    submission.update(exercise: new_exercise)
    assert_equal 'result', submission.result
    assert_equal 'code', submission.code
    assert File.exist?(submission.fs_path)
    assert_not File.exist?(path)
  end

  test 'transferring to another user should move the underlying result and code' do
    submission = create :submission, result: 'result', code: 'code', status: :correct
    path = submission.fs_path
    new_user = create :user
    submission.update(user: new_user)
    assert_equal 'result', submission.result
    assert_equal 'code', submission.code
    assert File.exist?(submission.fs_path)
    assert_not File.exist?(path)
  end

  test 'normalize_status should return unknown if unknown' do
    assert_equal 'unknown', Submission.normalize_status('no-exist')
  end

  test 'update_heatmap_matrix should always write something to the cache' do
    Rails.cache.expects(:write).once
    Submission.destroy_all
    Submission.update_heatmap_matrix

    create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current)
    Rails.cache.expects(:write).once
    Submission.update_heatmap_matrix
  end

  test 'update_punchcard_matrix should always write something to the cache' do
    Rails.cache.expects(:write).once
    Submission.destroy_all
    Submission.update_punchcard_matrix(timezone: Time.zone)

    create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current)
    Rails.cache.expects(:write).once
    Submission.update_punchcard_matrix(timezone: Time.zone)
  end

  test 'normal get should go to cache for heatmap' do
    Rails.cache.expects(:fetch).once
    Submission.heatmap_matrix
  end

  test 'normal get should go to cache for punhcard' do
    Rails.cache.expects(:fetch).once
    Submission.punchcard_matrix(timezone: Time.zone)
  end

  test 'update_heatmap_matrix should write an updated value to cache when fetch returns something' do
    2.times { create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current) }
    to_update = Submission.old_heatmap_matrix
    2.times { create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current) }
    Rails.cache.expects(:fetch).returns(to_update)
    Rails.cache.expects(:write).with(format(Submission::HEATMAP_MATRIX_CACHE_STRING, course_id: 'global', user_id: 'global'), Submission.old_heatmap_matrix)
    Submission.update_heatmap_matrix
  end

  test 'update_punchcard_matrix should write an updated value to cache when fetch returns something' do
    2.times { create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current) }
    to_update = Submission.old_punchcard_matrix(timezone: Time.zone)
    2.times { create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current) }
    Rails.cache.expects(:fetch).returns(to_update)
    Rails.cache.expects(:write).with(format(Submission::PUNCHCARD_MATRIX_CACHE_STRING, course_id: 'global', user_id: 'global', timezone: Time.zone.utc_offset), Submission.old_punchcard_matrix(timezone: Time.zone))
    Submission.update_punchcard_matrix(timezone: Time.zone)
  end

  test 'punchcard should take summer time into account' do
    Time.use_zone('Brussels') do
      s1 = create :submission, created_at: Time.zone.local(1996, 1, 29, 1, 1, 1)
      s2 = create :submission, created_at: Time.zone.local(1996, 7, 29, 1, 1, 1)
      # Just to make sure we don't do something stupid
      assert_equal s1.created_at.wday, s2.created_at.wday
      assert_equal 1, Submission.old_punchcard_matrix(timezone: Time.zone)[:value].count
    end
  end

  test 'punchcard should use timezone given even when system is set to another' do
    Time.use_zone('Brussels') do
      create :submission, created_at: Time.zone.local(1996, 1, 29, 1, 1, 1)
      assert_equal 1, Submission.old_punchcard_matrix(timezone: ActiveSupport::TimeZone.new('Seoul'))[:value]['0, 9']
    end
  end

  test 'clean calculate and update should give the same result for punchcard' do
    2.times { create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current) }
    to_update = Submission.old_punchcard_matrix(timezone: Time.zone)
    2.times { create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current) }
    updated = Submission.old_punchcard_matrix({ timezone: Time.zone }, to_update)
    assert_equal updated, Submission.old_punchcard_matrix(timezone: Time.zone)
  end

  test 'clean calculate and update should give the same result for heatmap' do
    2.times { create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current) }
    to_update = Submission.old_heatmap_matrix
    2.times { create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current) }
    updated = Submission.old_heatmap_matrix({}, to_update)
    assert_equal updated, Submission.old_heatmap_matrix
  end

  test 'user option should work for punchcard' do
    temp = users(:student)
    2.times { create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current), user: temp }
    user = users(:staff)
    3.times { create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current), user: user }
    assert_equal 3, Submission.old_punchcard_matrix(timezone: Time.zone, user: user)[:value].values.sum
  end

  test 'user option should work for heatmap' do
    temp = users(:student)
    2.times { create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current), user: temp }
    user = users(:staff)
    3.times { create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current), user: user }
    assert_equal 3, Submission.old_heatmap_matrix(user: user)[:value].values.sum
  end

  test 'course option should work for punchcard' do
    temp = courses(:course1)
    2.times { create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current), course: temp }
    course = create :course
    3.times { create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current), course: course }
    assert_equal 3, Submission.old_punchcard_matrix(timezone: Time.zone, course: course)[:value].values.sum
  end

  test 'course option should work for heatmap' do
    temp = courses(:course1)
    2.times { create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current), course: temp }
    course = create :course
    3.times { create :submission, created_at: Faker::Time.between(from: 5.years.ago, to: Time.current), course: course }
    assert_equal 3, Submission.old_heatmap_matrix(course: course)[:value].values.sum
  end

  test 'update to internal error should send exception notification' do
    submission = create :submission
    ExceptionNotifier.expects(:notify_exception).with { |_e, data| data[:data][:url].present? && data[:data][:judge].present? }
    submission.update(status: :'internal error')
  end

  test 'file is removed when submission is destroyed' do
    submission = create :submission
    assert File.exist?(submission.fs_path)
    submission.destroy
    assert_not File.exist?(submission.fs_path)
  end

  test 'time range should include correct submissions' do
    start = Time.zone.local(2021, 10, 10, 13, 5, 0)
    stop = Time.zone.local(2021, 11, 15, 9, 21, 0)
    create :submission, id: 1, created_at: Time.zone.local(2020, 10, 11, 13, 10, 0) # not included
    create :submission, id: 2, created_at: Time.zone.local(2021, 10, 10, 12, 0, 0) # not included
    create :submission, id: 3, created_at: Time.zone.local(2021, 10, 10, 13, 3, 0) # not included
    create :submission, id: 4, created_at: Time.zone.local(2021, 10, 10, 13, 15, 0) # included
    create :submission, id: 5, created_at: Time.zone.local(2021, 10, 10, 14, 0, 0) # included
    create :submission, id: 6, created_at: Time.zone.local(2021, 10, 20, 12, 0, 0) # included
    create :submission, id: 7, created_at: Time.zone.local(2021, 11, 15, 8, 0, 0) # included
    create :submission, id: 8, created_at: Time.zone.local(2021, 11, 15, 9, 18, 0) # included
    create :submission, id: 9, created_at: Time.zone.local(2021, 11, 15, 9, 25, 0) # not included
    create :submission, id: 10, created_at: Time.zone.local(2021, 11, 15, 10, 0, 0) # not included
    create :submission, id: 11, created_at: Time.zone.local(2022, 11, 14, 8, 0, 0) # not included

    subs = Submission.all
    assert_equal 11, subs.length
    subs = subs.in_time_range(start, stop)
    assert_equal 5, subs.length
    subs.each do |sub|
      assert_includes 4..8, sub.id
    end
  end

  class StatisticsTest < ActiveSupport::TestCase
    setup do
      @date = DateTime.new(1302, 7, 11, 13, 37, 42)
      @exercise = exercises(:python_exercise)
      @course = courses(:course1)
      @series = create :series, exercises: [@exercise], course: @course
      3.times do
        user = create :student, subscribed_courses: [@course]
        2.times do
          create :submission, user: user, exercise: @exercise, status: :correct, course: @course, created_at: @date
        end
        3.times do
          create :submission, user: user, exercise: @exercise, status: :wrong, course: @course, created_at: @date
        end
      end
    end

    test 'visualisation computations correct' do
      # violin
      result = Submission.violin_matrix(course: @course, series: @series)[:value]
      assert_equal result.length, 1 # one key: 1 exercise
      assert_equal result.values[0], [5, 5, 5]

      # stacked
      result = Submission.stacked_status_matrix(course: @course, series: @series)[:value]
      assert_equal result.length, 1 # one key: 1 exercise
      assert_equal result.values[0], { 'wrong' => 9, 'correct' => 6 }

      # time series
      result = Submission.timeseries_matrix(course: @course, series: @series)[:value]
      assert_equal result.length, 1 # one key: 1 exercise
      assert_equal result.values[0].length, 2 # 2 entries: one entry for each unique date (1) and for each unique state (2) => 2*1 entries
      assert_equal result.values[0], [{ date: @date, status: 'correct', count: 6 }, { date: @date, status: 'wrong', count: 9 }]

      # ctimeseries
      result = Submission.cumulative_timeseries_matrix(course: @course, series: @series)[:value]
      assert_equal result.length, 1 # one key: 1 exercise
      assert_equal result.values[0], [@date, @date, @date] # timestamp for each first correct submission (one for each user)
    end

    test 'visualisation work return empty list on empty series' do
      exercise = create :exercise
      series = create :series, exercises: [exercise], course: @course

      # violin
      result = Submission.violin_matrix(course: @course, series: series)[:value]
      assert_equal result.length, 0

      # stacked
      result = Submission.stacked_status_matrix(course: @course, series: series)[:value]
      assert_equal result.length, 0

      # time series
      result = Submission.timeseries_matrix(course: @course, series: series)[:value]
      assert_equal result.length, 0

      # ctimeseries
      result = Submission.cumulative_timeseries_matrix(course: @course, series: series)[:value]
      assert_equal result.length, 0
    end
  end
end
