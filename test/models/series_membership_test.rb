# == Schema Information
#
# Table name: series_memberships
#
#  id          :integer          not null, primary key
#  series_id   :integer
#  exercise_id :integer
#  order       :integer          default(999)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'test_helper'

class SeriesMembershipTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
