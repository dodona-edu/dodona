require 'test_helper'

class ScoresControllerTest < ActionDispatch::IntegrationTest
  def setup
    @evaluation = create :evaluation, :with_submissions
    @staff_member = create :staff
    @evaluation.series.course.administrating_members << @staff_member
    sign_in @staff_member
    exercise = @evaluation.evaluation_exercises.first
    @score_item = create :score_item, evaluation_exercise: exercise,
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
          score_item_id: @score_item.id,
          feedback_id: @feedback.id
        }
      }
      assert_response expected
      sign_out user if user.present?
      Score.where(score_item: @score_item, feedback: @feedback).first.destroy! if expected == :created
    end
  end

  test 'should not create score for invalid data' do
    post evaluation_scores_path(@evaluation, format: :json), params: {
      score: {
        score_item_id: @score_item.id,
        feedback_id: @feedback.id
      }
    }
    assert_response :unprocessable_entity
  end

  test 'should update score if course admin' do
    score = create :score, score_item: @score_item, feedback: @feedback
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

  test 'should not update score for invalid data' do
    score = create :score, score_item: @score_item, feedback: @feedback
    patch evaluation_score_path(@evaluation, score, format: :json), params: {
      score: {
        score: nil,
        expected_score: score.score.to_s
      }
    }
    assert_response :unprocessable_entity
  end

  test 'should not update score if expected is different' do
    score = create :score, score_item: @score_item, feedback: @feedback, score: '10.0'

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
      score = create :score, score_item: @score_item, feedback: @feedback
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

  test 'should not delete score if expected is different' do
    score = create :score, score_item: @score_item, feedback: @feedback, score: '10.0'

    delete evaluation_score_path(@evaluation, score, format: :json), params: {
      score: {
        expected_score: '11.0'
      }
    }
    assert_response :forbidden
  end

  test 'should handle errors when saving' do
    create :score, score_item: @score_item, feedback: @feedback, score: '10.0'

    post evaluation_scores_path(@evaluation, format: :json), params: {
      score: {
        score: '5.0',
        score_item_id: @score_item.id,
        feedback_id: @feedback.id
      }
    }

    assert_response :unprocessable_entity
    score = Score.find_by!(score_item: @score_item, feedback: @feedback)
    assert_equal BigDecimal('10'), score.score
  end
end
