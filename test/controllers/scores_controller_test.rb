require 'test_helper'

class ScoresControllerTest < ActionDispatch::IntegrationTest
  def setup
    @evaluation = create :evaluation, :with_submissions
    @staff_member = create :staff
    @evaluation.series.course.administrating_members << @staff_member
    sign_in @staff_member
    exercise = @evaluation.evaluation_exercises.first
    @rubric = create :rubric, evaluation_exercise: exercise,
                              description: 'Before test',
                              maximum: '10.0'
    @feedback = @evaluation.feedbacks.first
    @feedback.update!(completed: false)
  end

  test 'should create score if course admin' do
    [
      [@staff_member, :created],
      [create(:student), :forbidden],
      [create(:staff), :forbidden],
      [create(:zeus), :created],
      [nil, :unauthorized]
    ].each do |user, expected|
      sign_in user if user.present?
      post evaluation_scores_path(@evaluation, format: :json), params: {
        score: {
          score: '5.0',
          rubric_id: @rubric.id,
          feedback_id: @feedback.id
        }
      }
      assert_response expected
      sign_out user if user.present?
      Score.where(rubric: @rubric, feedback: @feedback).first.destroy! if expected == :created
    end
  end

  test 'should not create score for completed feedback' do
    @feedback.update!(completed: true)

    post evaluation_scores_path(@evaluation, format: :json), params: {
      score: {
        score: '5.0',
        rubric_id: @rubric.id,
        feedback_id: @feedback.id
      }
    }

    assert_response :forbidden
  end

  test 'should update score if course admin' do
    score = create :score, rubric: @rubric, feedback: @feedback
    [
      [@staff_member, :success],
      [create(:student), :forbidden],
      [create(:staff), :forbidden],
      [create(:zeus), :success],
      [nil, :unauthorized]
    ].each do |user, expected|
      sign_in user if user.present?
      patch evaluation_score_path(@evaluation, score, format: :json), params: {
        score: {
          score: '6.0',
          expected_score: score.score.to_s
        }
      }
      assert_response expected
      sign_out user if user.present?
    end
  end

  test 'should not update score if feedback is completed' do
    score = create :score, rubric: @rubric, feedback: @feedback
    @feedback.update!(completed: true)

    patch evaluation_score_path(@evaluation, score, format: :json), params: {
      score: {
        score: '6.0',
        expected_score: score.score.to_s
      }
    }
    assert_response :forbidden
  end

  test 'should not update score if expected is different' do
    score = create :score, rubric: @rubric, feedback: @feedback, score: '10.0'

    patch evaluation_score_path(@evaluation, score, format: :json), params: {
      score: {
        score: '6.0',
        expected_score: '11.0'
      }
    }
    assert_response :forbidden
  end

  test 'should delete score if course admin' do
    [
      [@staff_member, :no_content],
      [create(:student), :forbidden],
      [create(:staff), :forbidden],
      [create(:zeus), :no_content],
      [nil, :unauthorized]
    ].each do |user, expected|
      sign_in user if user.present?
      score = create :score, rubric: @rubric, feedback: @feedback
      delete evaluation_score_path(@evaluation, score, format: :json), params: {
        score: {
          expected_score: score.score.to_s
        }
      }
      assert_response expected
      sign_out user if user.present?
      score.destroy!
    end
  end

  test 'should not delete score if feedback is completed' do
    score = create :score, rubric: @rubric, feedback: @feedback
    @feedback.update!(completed: true)

    delete evaluation_score_path(@evaluation, score, format: :json), params: {
      score: {
        expected_score: score.score.to_s
      }
    }
    assert_response :forbidden
  end

  test 'should not delete score if expected is different' do
    score = create :score, rubric: @rubric, feedback: @feedback, score: '10.0'

    delete evaluation_score_path(@evaluation, score, format: :json), params: {
      score: {
        expected_score: '11.0'
      }
    }
    assert_response :forbidden
  end
end
