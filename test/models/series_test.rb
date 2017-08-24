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
  setup do
    @series = create :series
  end

  test 'factory should create series' do
    assert_not_nil @series
  end

  test 'indianio_token should be set' do
    assert @series.indianio_token.present?
  end

  test 'access_token should only be set when hidden' do
    @series.update(visibility: 'open')
    assert_nil @series.access_token
    @series.update(visibility: 'hidden')
    assert @series.access_token.present?
    @series.update(visibility: 'closed')
    assert_nil @series.access_token
  end
end
