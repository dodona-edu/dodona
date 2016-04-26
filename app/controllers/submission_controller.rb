class SubmissionsController < ApplicationController
  before_action :set_user, only: [:show]

  def index
    authorize Submission
    @submissions = Submission.all
  end

  def show
  end

  def create
    authorize Submission
    para = permitted_attributes(Submission)
    para[:user_id] = current_user.id
    @submission = Submission.new(para)
    if Pundit.policy!(current_user, @submission.exercise).show? && @submission.save
      render json: 'ok'
    else
      render json: 'failed', status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_submission
    @submission = Submission.find(params[:id])
    authorize @submission
  end
end
