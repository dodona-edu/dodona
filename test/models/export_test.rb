# == Schema Information
#
# Table name: exports
#
#  id         :bigint           not null, primary key
#  status     :integer          default("started"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#
# Indexes
#
#  index_exports_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

require 'test_helper'

class ExportTest < ActiveSupport::TestCase
  test 'can be created by factory' do
    assert_not_nil create(:export)
  end
end
