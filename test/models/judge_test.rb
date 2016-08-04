# == Schema Information
#
# Table name: judges
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  image      :string(255)
#  path       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  renderer   :string(255)      not null
#  runner     :string(255)      not null
#

require 'test_helper'

class JudgeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
