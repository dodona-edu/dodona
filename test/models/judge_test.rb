# == Schema Information
#
# Table name: judges
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  image      :string(255)
#  path       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  renderer   :string(255)      not null
#  remote     :string(255)
#  status     :integer
#

require 'test_helper'

class JudgeTest < ActiveSupport::TestCase
  test 'factory should create judge' do
    assert_not_nil create(:judge, :git_stubbed)
  end

  test 'renderer which is not a subclass of FeedBackTableRenderer should be invalid' do
    judge = build(:judge, :git_stubbed, renderer: 'NilClass')
    assert_not judge.valid?
    assert_equal ['should be a subclass of FeedbackTableRenderer'],
                 judge.errors[:renderer]
  end

  test 'renderer which is an unknown class should be invalid' do
    judge = build(:judge, :git_stubbed, renderer: 'OnbestaandeKlasse')
    assert_not judge.valid?
    assert_equal ['should be a class in scope'],
                 judge.errors[:renderer]
  end
end
