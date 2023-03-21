require 'test_helper'

class TimeHelperTest < ActiveSupport::TestCase
  include TimeHelper

  test 'days ago in words' do
    I18n.with_locale(:en) do
      time = Time.zone.now
      assert_equal 'today', days_ago_in_words(time)
      assert_equal 'yesterday', days_ago_in_words(1.day.ago)
      assert_equal '2 days ago', days_ago_in_words(2.days.ago)
    end
  end
end
