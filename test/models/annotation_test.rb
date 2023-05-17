# == Schema Information
#
# Table name: annotations
#
#  id                  :bigint           not null, primary key
#  line_nr             :integer
#  submission_id       :integer
#  user_id             :integer
#  annotation_text     :text(16777215)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  evaluation_id       :bigint
#  type                :string(255)      default("Annotation"), not null
#  question_state      :integer
#  last_updated_by_id  :integer          not null
#  course_id           :integer          not null
#  saved_annotation_id :bigint
#  thread_root_id      :integer
#  column              :integer
#  rows                :integer          default(1), not null
#  columns             :integer
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

  test 'can create a response to an annotation' do
    annotation = create :annotation, submission: @submission, user: @user
    response = create :annotation, submission: @submission, user: @annotating_user, thread_root: annotation
    assert_equal annotation, response.thread_root
  end

  test 'can create multiple responses to an annotation' do
    annotation = create :annotation, submission: @submission, user: @user
    response1 = create :annotation, submission: @submission, user: @annotating_user, thread_root: annotation
    response2 = create :annotation, submission: @submission, user: @annotating_user, thread_root: annotation
    assert_equal annotation, response1.thread_root
    assert_equal annotation, response2.thread_root
    assert_equal [response1, response2], annotation.responses
  end

  test 'cannot create a response to a response' do
    annotation = create :annotation, submission: @submission, user: @user
    response = create :annotation, submission: @submission, user: @annotating_user, thread_root: annotation
    response2 = create :annotation, submission: @submission, user: @annotating_user, thread_root: response
    assert_not response2.valid?
  end

  test 'A question with a response is marked as answered' do
    q = create :question, submission: @submission, user: @student
    assert q.unanswered?, 'Question should start as unanswered'

    create :annotation, submission: @submission, user: @annotating_user, thread_root: q

    assert q.reload.answered?, 'Question should have moved onto answered status'
  end

  test 'In a thread with multiple questions, only the last one can be unanswered' do
    q = create :question, submission: @submission, user: @student
    assert q.unanswered?

    create :annotation, submission: @submission, user: @annotating_user, thread_root: q
    assert q.reload.answered?

    q2 = create :question, submission: @submission, user: @student, thread_root: q
    assert q2.reload.unanswered?

    q3 = create :question, submission: @submission, user: @student, thread_root: q
    assert q2.reload.answered?
    assert q3.reload.unanswered?

    create :annotation, submission: @submission, user: @annotating_user, thread_root: q
    assert q.reload.answered?
    assert q2.reload.answered?
    assert q3.reload.answered?
  end

  test 'a question that is set to in progress transitions back to unanswered after delayed job execution' do
    q = create :question, submission: @submission, user: @student
    assert q.unanswered?

    with_delayed_jobs do
      q.update(question_state: :in_progress)
      assert q.reload.in_progress?
    end

    run_delayed_jobs
    assert q.reload.unanswered?
  end

  test 'should not reset question state to unanswered if it is answered before delayed job execution' do
    q = create :question, submission: @submission, user: @student
    assert q.unanswered?

    with_delayed_jobs do
      q.update(question_state: :in_progress)
      assert q.reload.in_progress?
      q.update(question_state: :answered)
    end

    run_delayed_jobs
    assert q.reload.answered?
  end
end
