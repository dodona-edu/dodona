# == Schema Information
#
# Table name: annotations
#
#  id                  :bigint           not null, primary key
#  annotation_text     :text(16777215)
#  column              :integer
#  columns             :integer
#  line_nr             :integer
#  question_state      :integer
#  rows                :integer          default(1), not null
#  type                :string(255)      default("Annotation"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  course_id           :integer          not null
#  evaluation_id       :bigint
#  last_updated_by_id  :integer          not null
#  saved_annotation_id :bigint
#  submission_id       :integer
#  thread_root_id      :integer
#  user_id             :integer
#
# Indexes
#
#  index_annotations_on_course_id_and_type_and_question_state  (course_id,type,question_state)
#  index_annotations_on_evaluation_id                          (evaluation_id)
#  index_annotations_on_last_updated_by_id                     (last_updated_by_id)
#  index_annotations_on_saved_annotation_id                    (saved_annotation_id)
#  index_annotations_on_submission_id                          (submission_id)
#  index_annotations_on_user_id                                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_id => courses.id)
#  fk_rails_...  (evaluation_id => evaluations.id)
#  fk_rails_...  (last_updated_by_id => users.id)
#  fk_rails_...  (saved_annotation_id => saved_annotations.id)
#  fk_rails_...  (submission_id => submissions.id)
#  fk_rails_...  (user_id => users.id)
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

    assert_predicate annotation, :valid?
  end

  test 'can not create annotation with negative line_nr' do
    annotation = build :annotation, submission: @submission, user: @annotating_user
    annotation.line_nr = -1

    assert_not annotation.valid?
  end

  test 'can create global annotation' do
    annotation = build :annotation, submission: @submission, user: @annotating_user
    annotation.line_nr = nil

    assert_predicate annotation, :valid?
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

    assert_predicate annotation, :valid?
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

    assert_predicate q, :unanswered?, 'Question should start as unanswered'

    create :annotation, submission: @submission, user: @annotating_user, thread_root: q

    assert_predicate q.reload, :answered?, 'Question should have moved onto answered status'
  end

  test 'In a thread with multiple questions, only the last one can be unanswered' do
    q = create :question, submission: @submission, user: @student

    assert_predicate q, :unanswered?

    create :annotation, submission: @submission, user: @annotating_user, thread_root: q

    assert_predicate q.reload, :answered?

    q2 = create :question, submission: @submission, user: @student, thread_root: q

    assert_predicate q2.reload, :unanswered?

    q3 = create :question, submission: @submission, user: @student, thread_root: q

    assert_predicate q2.reload, :answered?
    assert_predicate q3.reload, :unanswered?

    create :annotation, submission: @submission, user: @annotating_user, thread_root: q

    assert_predicate q.reload, :answered?
    assert_predicate q2.reload, :answered?
    assert_predicate q3.reload, :answered?
  end

  test 'a question that is set to in progress transitions back to unanswered after delayed job execution' do
    q = create :question, submission: @submission, user: @student

    assert_predicate q, :unanswered?

    with_delayed_jobs do
      q.update(question_state: :in_progress)

      assert_predicate q.reload, :in_progress?
    end

    run_delayed_jobs

    assert_predicate q.reload, :unanswered?
  end

  test 'should not reset question state to unanswered if it is answered before delayed job execution' do
    q = create :question, submission: @submission, user: @student

    assert_predicate q, :unanswered?

    with_delayed_jobs do
      q.update(question_state: :in_progress)

      assert_predicate q.reload, :in_progress?
      q.update(question_state: :answered)
    end

    run_delayed_jobs

    assert_predicate q.reload, :answered?
  end

  test 'delayed job should not crash if question is deleted before execution' do
    q = create :question, submission: @submission, user: @student

    assert_predicate q, :unanswered?

    with_delayed_jobs do
      q.update(question_state: :in_progress)

      assert_predicate q.reload, :in_progress?
      q.destroy
    end

    assert_nil Question.find_by(id: q.id)

    run_delayed_jobs
  end
end
