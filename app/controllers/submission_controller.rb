class SubmissionsController < ApplicationController
  before_action :set_submission, only: [:show]

  def index
    authorize Submission
    @submissions = policy_scope(Submission)
    if params[:user_id]
      @user = User.find(params[:user_id])
      @submissions = @submissions.of_user(@user)
    end
    if params[:exercise_name]
      @exercise = Exercise.find_by_name(params[:exercise_name])
      @submissions = @submissions.of_exercise(@exercise)
    end
  end

  def show
  end

  def create
    authorize Submission
    para = permitted_attributes(Submission)
    para[:user_id] = current_user.id
    @submission = Submission.new(para)
    if Pundit.policy!(current_user, @submission.exercise).show? && @submission.save
      render json: { status: 'ok' }
    else
      render json: { status: 'failed' }, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_submission
    @submission = Submission.find(params[:id])
    authorize @submission
  end
end
