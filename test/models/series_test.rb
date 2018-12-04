# == Schema Information
#
# Table name: series
#
#  id             :integer          not null, primary key
#  course_id      :integer
#  name           :string(255)
#  description    :text(65535)
#  visibility     :integer
#  order          :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  deadline       :datetime
#  access_token   :string(255)
#  indianio_token :string(255)
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

  test 'enabling indianio_support should generate a new token if there was none' do
    @series.indianio_support = true
    assert_not_nil @series.indianio_token

    @series.indianio_token = nil

    @series.indianio_support = '1'
    assert_not_nil @series.indianio_token

    @series.indianio_token = nil

    @series.indianio_support = 1
    assert_not_nil @series.indianio_token
  end

  test 'indianio_support should be true when there is a token' do
    @series.indianio_token = 'something'
    assert_equal true, @series.indianio_support
  end

  test 'disabling indianio_support should set token to nil' do
    @series.indianio_token = 'something'
    @series.indianio_support = false
    assert_nil @series.indianio_token

    @series.indianio_token = 'something'

    @series.indianio_support = '0'
    assert_nil @series.indianio_token

    @series.indianio_token = 'something'

    @series.indianio_support = 0
    assert_nil @series.indianio_token
  end

  test 'generate_token should generate a new token' do
    indianio = 'indianio'
    access = 'access'
    @series.update(indianio_token: 'indianio', access_token: 'access')
    @series.generate_token :indianio_token
    assert_not_equal indianio, @series.indianio_token

    @series.generate_token :access_token
    assert_not_equal access, @series.indianio_token
  end

  test 'generating token for unkown type should give an error' do
    assert_raises 'unknown token type' do
      @series.generate_token :unknown_token
    end
  end

  test 'access_token should always be set' do
    @series.update(visibility: 'open')
    assert @series.access_token.present?
    @series.update(visibility: 'hidden')
    assert @series.access_token.present?
    @series.update(visibility: 'closed')
    assert @series.access_token.present?
  end
end
