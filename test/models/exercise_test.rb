# == Schema Information
#
# Table name: exercises
#
#  id            :integer          not null, primary key
#  name_nl       :string(255)
#  name_en       :string(255)
#  visibility    :integer          default("open")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  path          :string(255)
#  format        :string(255)
#  repository_id :integer
#  judge_id      :integer
#

require 'test_helper'

class ExerciseTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
