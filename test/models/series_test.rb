# == Schema Information
#
# Table name: series
#
#  id          :integer          not null, primary key
#  course_id   :integer
#  name        :string(255)
#  description :text(65535)
#  visibility  :integer
#  order       :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deadline    :datetime
#  token       :string(255)
#

require 'test_helper'

class SeriesTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
