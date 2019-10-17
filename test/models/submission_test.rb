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
  FILE_LOCATION = Rails.root.join('test', 'files', 'output.json')

  test 'factory should create submission' do
    assert_not_nil create(:submission)
  end

  test 'submissions should be rate limited for a user' do
    user = create :user
    create :submission, user: user
    submission = build :submission, :rate_limited, user: user
    assert_not submission.valid?

    later = Time.zone.now + 10.seconds

    Time.stubs(:now).returns(later)

    later_submission = build :submission, :rate_limited, user: user
    assert later_submission.valid?, 'should be able to create submission after waiting'
  end

  test 'submissions should not be rate limited for different users' do
    user = create :user
    other = create :user
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
    submission = create :submission, result: json
    user = create :user, permission: :student
    result = JSON.parse(submission.safe_result(user), symbolize_names: true)
    assert_equal 1, result[:groups].count
  end

  test 'safe_result should remove zeus tabs for staff' do
    json = FILE_LOCATION.read
    submission = create :submission, result: json
    user = create :user, permission: :staff
    result = JSON.parse(submission.safe_result(user), symbolize_names: true)
    assert_equal 2, result[:groups].count
  end

  test 'safe_result should display all tabs to zeus' do
    json = FILE_LOCATION.read
    submission = create :submission, result: json
    user = create :zeus
    result = JSON.parse(submission.safe_result(user), symbolize_names: true)
    assert_equal 3, result[:groups].count
  end

  test 'safe_result should remove staff and zeus messages for students' do
    json = FILE_LOCATION.read
    submission = create :submission, result: json
    user = create :user, permission: :student
    result = JSON.parse(submission.safe_result(user), symbolize_names: true)
    assert_equal 2, result[:messages].count
    assert_equal 2, result[:groups][0][:messages].count
    assert_equal 2, result[:groups][0][:groups][0][:messages].count
    assert_equal 2, result[:groups][0][:groups][0][:groups][0][:messages].count
    assert_equal 2, result[:groups][0][:groups][0][:groups][0][:tests][0][:messages].count
  end

  test 'safe_result should remove zeus message for staff' do
    json = FILE_LOCATION.read
    submission = create :submission, result: json
    user = create :user, permission: :staff
    result = JSON.parse(submission.safe_result(user), symbolize_names: true)
    assert_equal 2, result[:groups].count
    assert_equal 3, result[:messages].count
    assert_equal 3, result[:groups][0][:messages].count
    assert_equal 3, result[:groups][0][:groups][0][:messages].count
    assert_equal 3, result[:groups][0][:groups][0][:groups][0][:messages].count
    assert_equal 3, result[:groups][0][:groups][0][:groups][0][:tests][0][:messages].count
  end

  test 'transferring to another course should move the underlying result and code' do
    submission = create :submission, result: 'result', code: 'code'
    path = submission.fs_path
    new_course = create :course
    submission.update(course: new_course)
    assert_equal 'result', submission.result
    assert_equal 'code', submission.code
    assert File.exist?(submission.fs_path)
    assert_not File.exist?(path)
  end

  test 'transferring to another exercise should move the underlying result and code' do
    submission = create :submission, result: 'result', code: 'code'
    path = submission.fs_path
    new_exercise = create :exercise
    submission.update(exercise: new_exercise)
    assert_equal 'result', submission.result
    assert_equal 'code', submission.code
    assert File.exist?(submission.fs_path)
    assert_not File.exist?(path)
  end

  test 'transferring to another user should move the underlying result and code' do
    submission = create :submission, result: 'result', code: 'code'
    path = submission.fs_path
    new_user = create :user
    submission.update(user: new_user)
    assert_equal 'result', submission.result
    assert_equal 'code', submission.code
    assert File.exist?(submission.fs_path)
    assert_not File.exist?(path)
  end

  test 'update_heatmap_matrix should always write something to the cache' do
    Rails.cache.expects(:write).once
    Submission.destroy_all
    Submission.update_heatmap_matrix(nil, nil)

    create :submission, status: :correct
    Rails.cache.expects(:write).once
    Submission.update_heatmap_matrix(nil, nil)
  end

  test 'update_punchcard_matrix should always write something to the cache' do
    Rails.cache.expects(:write).once
    Submission.destroy_all
    Submission.update_punchcard_matrix(nil, nil)

    create :submission, status: :correct
    Rails.cache.expects(:write).once
    Submission.update_punchcard_matrix(nil, nil)
  end

  test 'update to internal error should send exception notification' do
    submission = create :submission
    ExceptionNotifier.expects(:notify_exception)
    submission.update(status: :"internal error")
  end
end
