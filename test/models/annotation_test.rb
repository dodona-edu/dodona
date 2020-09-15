# == Schema Information
#
# Table name: annotations
#
#  id              :bigint           not null, primary key
#  line_nr         :integer
#  submission_id   :integer
#  user_id         :integer
#  annotation_text :text(65535)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  evaluation_id   :bigint
#  type            :string(255)      default("Annotation"), not null
#  question_state  :integer
#
require 'test_helper'

class AnnotationTest < ActiveSupport::TestCase
  setup do
    @user = create :user, {}
    @submission = create :submission, code: "line1\nline2\nline3\n", user: @user
  end

  test 'can create line-bound annotation' do
    annotating_user = create :user
    annotation = create :annotation, line_nr: 1, submission: @submission, user: annotating_user
    assert annotation.valid?
  end

  test 'can not create annotation with negative line_nr' do
    annotating_user = create :user
    annotation = create :annotation, submission: @submission, user: annotating_user
    annotation.line_nr = -1
    assert_not annotation.valid?
  end

  test 'can create global annotation' do
    annotating_user = create :user
    annotation = create :annotation, submission: @submission, user: annotating_user
    annotation.line_nr = nil
    assert annotation.valid?
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
    annotation.annotation_text = 'A' * 2049 # max length of annotation text is 2048 -> trigger failure
    assert_not annotation.valid?
  end

  test 'user can create annotation on own submission' do
    annotation = create :annotation, submission: @submission, user: @user
    assert annotation.valid?
  end
end
