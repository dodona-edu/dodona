# == Schema Information
#
# Table name: exports
#
#  id         :bigint           not null, primary key
#  user_id    :integer
#  status     :integer          default("started"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class ExportTest < ActiveSupport::TestCase
  test 'can be created by factory' do
    assert_not_nil create(:export)
  end
end
