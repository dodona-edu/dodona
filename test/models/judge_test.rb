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
#  runner     :string(255)      not null
#  remote     :string(255)
#

require 'test_helper'

class JudgeTest < ActiveSupport::TestCase
  test 'factory should create judge' do
    assert_not_nil create(:judge, :git_stubbed)
  end

  test 'renderer which is not a subclass of FeedBackTableRenderer should be invalid' do
    judge = build(:judge, renderer: 'NilClass')
    assert_not judge.valid?
    assert_equal ['should be a subclass of FeedbackTableRenderer'],
                 judge.errors[:renderer]
  end

  test 'renderer which is an unknown class should be invalid' do
    judge = build(:judge, renderer: 'OnbestaandeKlasse')
    assert_not judge.valid?
    assert_equal ['should be a class in scope'],
                 judge.errors[:renderer]
  end

  test 'runner which is not a subclass of FeedBackTableRenderer should be invalid' do
    judge = build(:judge, runner: 'NilClass')
    assert_not judge.valid?
    assert_equal ['should be a subclass of SubmissionRunner'],
                 judge.errors[:runner]
  end

  test 'runner which is an unknown class should be invalid' do
    judge = build(:judge, runner: 'OnbestaandeKlasse')
    assert_not judge.valid?
    assert_equal ['should be a class in scope'],
                 judge.errors[:runner]
  end
end
