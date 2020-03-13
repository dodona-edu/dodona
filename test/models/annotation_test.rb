require 'test_helper'

class AnnotationTest < ActiveSupport::TestCase
  setup do
    @user = create :user, {}
    @submission = create :submission, user: @user
  end

  test 'can create normal annotation' do
    annotating_user = create :user
    annotation = create :annotation, submission: @submission, user: annotating_user
    assert annotation.valid?
  end

  test 'can not create annotation with line_nr below 0' do
    annotating_user = create :user
    annotation = create :annotation, submission: @submission, user: annotating_user
    annotation.line_nr = -1
    assert_not annotation.valid?
  end

  test 'can not create annotation without some sort of message' do
    annotating_user = create :user
    annotation = create :annotation, submission: @submission, user: annotating_user
    annotation.annotation_text = ''
    assert_not annotation.valid?
  end

  test 'can not create annotation with an enormous message' do
    annotating_user = create :user
    annotation = create :annotation, submission: @submission, user: annotating_user
    annotation.annotation_text = Faker::Lorem.paragraph sentence_count: 2048
    assert_not annotation.valid?
  end

  test 'user can create annotation on own submission' do
    annotation = create :annotation, submission: @submission, user: @user
    assert annotation.valid?
  end
end
