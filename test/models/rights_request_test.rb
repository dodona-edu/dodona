# == Schema Information
#
# Table name: rights_requests
#
#  id               :bigint           not null, primary key
#  user_id          :integer          not null
#  institution_name :string(255)
#  context          :text(65535)      not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
require 'test_helper'

class RightsRequestTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
