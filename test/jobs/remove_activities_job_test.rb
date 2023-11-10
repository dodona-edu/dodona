require 'test_helper'

class RemoveActivitiesJobTest < ActiveJob::TestCase
  test 'should remove "removed" draft activities' do
    c = create :content_page
    create :activity_read_state, activity: c
    c.update status: :removed, draft: true, updated_at: 2.months.ago
    e = create :exercise
    create :submission, exercise: e
    e.update status: :removed, draft: true, updated_at: 2.months.ago
    s = create :series
    s.activities << c
    s.activities << e

    assert_difference 'ContentPage.count', -1 do
      assert_difference 'Exercise.count', -1 do
        RemoveActivitiesJob.perform_now
      end
    end
  end

  test 'should remove "removed" activities with no series memberships and no submissions' do
    create :content_page, status: :removed, draft: false, updated_at: 2.months.ago
    create :exercise, status: :removed, draft: false, updated_at: 2.months.ago

    assert_difference 'ContentPage.count', -1 do
      assert_difference 'Exercise.count', -1 do
        RemoveActivitiesJob.perform_now
      end
    end
  end

  test 'should not remove "removed" activities with series memberships' do
    c = create :content_page, status: :removed, draft: false, updated_at: 2.months.ago
    e = create :exercise, status: :removed, draft: false, updated_at: 2.months.ago
    s = create :series
    s.activities << c
    s.activities << e

    assert_no_difference 'ContentPage.count' do
      assert_no_difference 'Exercise.count' do
        RemoveActivitiesJob.perform_now
      end
    end
  end

  test 'should not remove "removed" activities with more than 25 submissions' do
    e = create :exercise, status: :removed, draft: false, updated_at: 2.months.ago
    create_list :submission, 26, exercise: e

    assert_no_difference 'Exercise.count' do
      RemoveActivitiesJob.perform_now
    end
  end

  test 'should remove "removed" activities with less than 25 submissions and last submission more than 1 month ago' do
    e = create :exercise, status: :removed, draft: false, updated_at: 2.months.ago
    create_list :submission, 21, exercise: e, created_at: 2.months.ago

    assert_difference 'Submission.count', -21 do
      assert_difference 'Exercise.count', -1 do
        RemoveActivitiesJob.perform_now
      end
    end
  end

  test 'should not remove "removed" activities with less than 25 submissions and last submission less than 1 month ago' do
    e = create :exercise, status: :removed, draft: false, updated_at: 2.months.ago
    create_list :submission, 5, exercise: e, created_at: 2.months.ago
    create_list :submission, 3, exercise: e, created_at: 2.weeks.ago

    assert_no_difference 'Submission.count' do
      assert_no_difference 'Exercise.count' do
        RemoveActivitiesJob.perform_now
      end
    end
  end

  test 'should not removed non removed activities' do
    create :exercise, updated_at: 2.months.ago
    create :content_page, updated_at: 2.months.ago
    create :exercise, draft: true, updated_at: 2.months.ago
    create :content_page, draft: true, updated_at: 2.months.ago

    assert_no_difference 'Exercise.count' do
      assert_no_difference 'ContentPage.count' do
        RemoveActivitiesJob.perform_now
      end
    end
  end

  test 'should not remove activities updated less than 1 month ago' do
    create :exercise, status: :removed, draft: true, updated_at: 2.weeks.ago

    assert_no_difference 'Exercise.count' do
      RemoveActivitiesJob.perform_now
    end
  end

  test 'should reschedule itself' do
    assert_enqueued_with(job: RemoveActivitiesJob) do
      RemoveActivitiesJob.perform_now
    end
  end
end
