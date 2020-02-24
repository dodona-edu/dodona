class AnnotationsController < ApplicationController
  before_action :set_submission
  skip_before_action :verify_authenticity_token if Rails.env.development?

  def index
    authorize @submission, :show?
    @annotations = @submission.annotations
  end

  def create
    @annotation = Annotation.new(permitted_attributes(Annotation))
    @annotation.user = current_user
    @annotation.submission = @submission
    authorize @annotation
    if @annotation.save
      render 'annotations/annotation.json', status: :created, format: :json
    else
      render json: @annotation.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @annotation
    if @annotation.update(permitted_attributes(@annotation))
      render 'annotations/annotation.json', format: :json
    else
      render json: @annotation.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @annotation
    @annotation.destroy
    render json: {}, status: :no_content
  end

  private

  def set_submission
    @submission = Submission.find params[:submission_id]
    @annotation = @submission.annotations.find params[:id] if params[:id]
    @current_user = current_user
  end
end
