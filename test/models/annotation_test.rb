# == Schema Information
#
# Table name: annotations
#
#  id                 :bigint           not null, primary key
#  line_nr            :integer
#  submission_id      :integer
#  user_id            :integer
#  annotation_text    :text(16777215)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  evaluation_id      :bigint
#  type               :string(255)      default("Annotation"), not null
#  question_state     :integer
#  last_updated_by_id :integer          not null
#  course_id          :integer          not null
#
require 'test_helper'

class AnnotationTest < ActiveSupport::TestCase
  setup do
    @user = users(:student)
    @annotating_user = users(:staff)
    course = courses(:course1)
    @submission = create :submission, code: "line1\nline2\nline3\n", user: @user, course: course
  end

  test 'can create line-bound annotation' do
    annotation = build :annotation, line_nr: 1, submission: @submission, user: @annotating_user
    assert annotation.valid?
  end

  test 'can not create annotation with negative line_nr' do
    annotation = build :annotation, submission: @submission, user: @annotating_user
    annotation.line_nr = -1
    assert_not annotation.valid?
  end

  test 'can create global annotation' do
    annotation = build :annotation, submission: @submission, user: @annotating_user
    annotation.line_nr = nil
    assert annotation.valid?
  end

  test 'can not create annotation without some sort of message' do
    annotation = build :annotation, submission: @submission, user: @annotating_user
    annotation.annotation_text = ''
    assert_not annotation.valid?
  end

  test 'can not create annotation with an enormous message' do
    annotation = build :annotation, submission: @submission, user: @annotating_user
    annotation.annotation_text = 'A' * 10_001 # max length of annotation text is 10.000 -> trigger failure
    assert_not annotation.valid?
  end

  test 'user can create annotation on own submission' do
    annotation = build :annotation, submission: @submission, user: @user
    assert annotation.valid?
  end

  test 'last_updated_by is set to creator by default' do
    annotation = create :annotation, submission: @submission, user: @user
    assert_equal @user, annotation.last_updated_by
  end

  test 'last_updated_by can be changed' do
    annotation = create :annotation, submission: @submission, user: @user
    other_user = @annotating_user
    annotation.update(last_updated_by: other_user)
    annotation.reload
    assert_equal other_user, annotation.last_updated_by
  end
end
