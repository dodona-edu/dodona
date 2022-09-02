require 'test_helper'

class EvaluationExerciseControllerTest < ActionDispatch::IntegrationTest
  def setup
    @evaluation = create :evaluation, :with_submissions
    @staff_member = users(:staff)
    @evaluation.series.course.administrating_members << @staff_member
    sign_in @staff_member
  end

  test 'can update visibility as course admin' do
    evaluation_exercise = @evaluation.evaluation_exercises.first

    [
      [@staff_member, :success],
      [users(:student), :forbidden],
      [create(:staff), :forbidden],
      [users(:zeus), :success],
      [nil, :unauthorized]
    ].each do |user, expected|
      sign_in user if user.present?

      evaluation_exercise.update!(visible_score: true)
      assert evaluation_exercise.visible_score?

      patch evaluation_exercise_path(evaluation_exercise, format: :js), params: {
        evaluation_exercise: {
          visible_score: false
        }
      }
      assert_response expected
      evaluation_exercise.reload
      if expected == :success
        assert_not evaluation_exercise.visible_score?
      else
        assert evaluation_exercise.visible_score?
      end

      sign_out user if user.present?
    end
  end
end
