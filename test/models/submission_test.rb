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

  test 'submission with closed exercise should not be creatable' do
    submission = build(:submission)
    submission.exercise.update(visibility: 'closed')
    assert_not submission.save
  end
end
