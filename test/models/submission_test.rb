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
#

require 'test_helper'

class SubmissionTest < ActiveSupport::TestCase
  test 'factory should create submission' do
    assert_not_nil create(:submission)
  end

  test 'submissions should be rate limited for a user' do
    user = create :user
    create :submission, user: user
    submission = build :submission, :rate_limited, user: user
    assert_not submission.valid?

    later = Time.now + 10.seconds

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
end
