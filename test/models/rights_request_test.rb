# == Schema Information
#
# Table name: rights_requests
#
#  id               :bigint           not null, primary key
#  context          :text(65535)      not null
#  institution_name :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :integer          not null
#
require 'test_helper'

class RightsRequestTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
