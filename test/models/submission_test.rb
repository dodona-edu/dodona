# == Schema Information
#
# Table name: submissions
#
#  id          :integer          not null, primary key
#  exercise_id :integer
#  user_id     :integer
#  code        :text(65535)
#  result      :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  status      :integer
#

require 'test_helper'

class SubmissionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
