require 'test_helper'

class AnnotationPolicyTest < ActiveSupport::TestCase
  setup do
    @user = users(:student)
    @annotating_user = users(:staff)
    course = courses(:course1)
    @submission = create :submission, code: "line1\nline2\nline3\n", user: @user, course: course
  end

  test 'anonymous is true when evaluation exists and student views annotation from teacher' do
    annotation = create :annotation, :with_evaluation, submission: @submission, user: @annotating_user
    assert Pundit.policy(@user, annotation).anonymous?
  end

  test 'anonymous is false when evaluation exists and person views own annotation' do
    annotation = create :annotation, :with_evaluation, submission: @submission, user: @user
    assert_not Pundit.policy(@user, annotation).anonymous?
  end

  test 'anonymous is false when evaluation does not exist' do
    annotation = create :annotation, submission: @submission, user: @annotating_user
    assert_not Pundit.policy(@user, annotation).anonymous?
  end
end
