class SubmissionsController < ApplicationController
  before_action :set_submission, only: [:show, :download, :evaluate]
  skip_before_action :verify_authenticity_token, only: [:create]

  def index
    authorize Submission
    @submissions = policy_scope(Submission).paginate(page: params[:page])
    if params[:user_id]
      @user = User.find(params[:user_id])
      @submissions = @submissions.of_user(@user)
    end
    if params[:exercise_id]
      @exercise = Exercise.find(params[:exercise_id])
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

  def download
    data = @submission.code
    filename = @submission.exercise.name.tr(' ', '_') + '.js'
    send_data data, type: 'application/octet-stream', filename: filename, disposition: 'attachment', x_sendfile: true
  end

  def evaluate
    @submission.evaluate_delayed
    redirect_to(@submission)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_submission
    @submission = Submission.find(params[:id])
    authorize @submission
  end
end
