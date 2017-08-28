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

  test 'indianio_token should not be set' do
    assert_nil @series.indianio_token
  end

  test 'generate_indianio_token! should work' do
    @series.generate_indianio_token!
    token = Series.find(@series.id).indianio_token
    assert_not_nil token
    @series.generate_indianio_token!
    assert_not_equal token, Series.find(@series.id).indianio_token
  end

  test 'delete_indianio_token! should work' do
    @series.generate_indianio_token!
    @series = Series.find(@series.id)

    @series.delete_indianio_token!
    assert_nil @series.reload.indianio_token
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
