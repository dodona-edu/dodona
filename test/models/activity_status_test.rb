# == Schema Information
#
# Table name: activity_statuses
#
#  id                          :bigint           not null, primary key
#  accepted                    :boolean          default(FALSE), not null
#  accepted_before_deadline    :boolean          default(FALSE), not null
#  solved                      :boolean          default(FALSE), not null
#  started                     :boolean          default(FALSE), not null
#  solved_at                   :datetime
#  activity_id                 :integer          not null
#  series_id                   :integer
#  user_id                     :integer          not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  last_submission_id          :integer
#  last_submission_deadline_id :integer
#  best_submission_id          :integer
#  best_submission_deadline_id :integer
#
require 'test_helper'

class ActivityStatusTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
