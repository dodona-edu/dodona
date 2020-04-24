# == Schema Information
#
# Table name: exercise_statuses
#
#  id                       :bigint           not null, primary key
#  accepted                 :boolean          default(FALSE), not null
#  accepted_before_deadline :boolean          default(FALSE), not null
#  solved                   :boolean          default(FALSE), not null
#  started                  :boolean          default(FALSE), not null
#  solved_at                :datetime
#  exercise_id              :integer          not null
#  series_id                :integer
#  user_id                  :integer          not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
require 'test_helper'

class ActivityStatusTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
