# == Schema Information
#
# Table name: notifications
#
#  id              :bigint           not null, primary key
#  message         :string(255)      not null
#  notifiable_type :string(255)
#  read            :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  notifiable_id   :bigint
#  user_id         :integer          not null
#

require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  test 'can be created by factory' do
    assert_not_nil create(:notification)
  end
end
