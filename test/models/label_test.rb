# == Schema Information
#
# Table name: labels
#
#  id    :bigint           not null, primary key
#  color :integer          not null
#  name  :string(255)      not null
#
# Indexes
#
#  index_labels_on_name  (name) UNIQUE
#

require 'test_helper'

class LabelTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
