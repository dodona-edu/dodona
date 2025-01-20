# == Schema Information
#
# Table name: announcements
#
#  id                  :bigint           not null, primary key
#  start_delivering_at :datetime
#  stop_delivering_at  :datetime
#  style               :integer          not null
#  text_en             :text(65535)      not null
#  text_nl             :text(65535)      not null
#  user_group          :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  institution_id      :bigint
#
# Indexes
#
#  index_announcements_on_institution_id  (institution_id)
#
# Foreign Keys
#
#  fk_rails_...  (institution_id => institutions.id)
#
require 'test_helper'

class AnnouncementTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
