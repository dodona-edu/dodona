# == Schema Information
#
# Table name: exercise_tokens
#
#  id          :integer          not null, primary key
#  token       :string(255)
#  exercise_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'test_helper'

class ExerciseTokenTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
