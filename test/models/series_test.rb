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
  test 'factory should create series' do
    assert_not_nil create :series
  end

  test 'only hidden series should have token' do
    assert_not_nil create(:series, visibility: 'hidden').token
    assert_nil create(:series, visibility: 'open').token
    assert_nil create(:series, visibility: 'closed').token
  end

  test 'changing visibility should reset token' do
    series = create(:series, visibility: 'hidden')
    token_before = series.token
    series.update(visibility: 'closed')
    series.update(visibility: 'hidden')
    token_after = series.token
    assert_not_equal token_before, token_after
  end
end
